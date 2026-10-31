import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:untitled/common/managers/logger.dart';
import 'package:untitled/models/status_message_model.dart';

import 'api_service.dart';

class NewApiService {
  static final shared = NewApiService();

  /// 共享 client：复用 keep-alive 连接池。
  /// 此前每个请求都新建并关闭 client，跨境链路上每次都要完整 DNS+TCP+TLS 握手，
  /// 遇到丢包时握手重试可达数秒，是接口慢的主因。
  final http.Client _client = http.Client();

  final Map<CancelToken, http.Client> _activeClients = {};

  Map<String, String> get header {
    Map<String, String> map = {'apikey': '123'};

    return map;
  }

  Future<T> call<T>({
    required String url,
    Map<String, dynamic>? param,
    CancelToken? cancelToken,
    T Function(Map<String, dynamic> json)? fromJson,
  }) async {
    // 无取消需求时使用共享 client；带 cancelToken 时才用独立 client（目前无调用方）
    final client = cancelToken != null ? http.Client() : _client;
    if (cancelToken != null) {
      _activeClients[cancelToken] = client;
    }

    Map<String, dynamic> params = {};
    param?.removeWhere(
      (key, value) => value == null,
    );
    param?.forEach((key, value) {
      if (value is List) {
        for (int i = 0; i < value.length; i++) {
          params['$key[$i]'] = jsonEncode(value[i]);
        }
      } else {
        params[key] = "$value";
      }
    });

    Loggers.info("URL: $url");
    Loggers.info("Headers: ${JsonEncoder.withIndent('  ').convert(header)}");
    Loggers.info(
        "Parameters: ${params.isEmpty ? "Empty" : JsonEncoder.withIndent('  ').convert(params)}");

    try {
      // 必须有超时：响应在传输中丢失时（弱网/跨境链路），无超时的 Future 会永远挂起，
      // 导致 UI 一直转圈。超时后抛 TimeoutException，由调用方处理。
      final response = await client
          .post(
            Uri.parse(url),
            headers: header,
            body: params,
          )
          .timeout(const Duration(seconds: 20));

      if (cancelToken?.isCancelled ?? false) {
        if (kDebugMode) {
          Loggers.warning("Request cancelled: $url");
        }
        throw Exception('Request was cancelled');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decodedResponse =
            jsonDecode(response.body) as Map<String, dynamic>;
        final prettyString =
            const JsonEncoder.withIndent('  ').convert(decodedResponse);
        Loggers.info(prettyString);

        // Use the provided `fromJson` function to parse the response

        var model = StatusMessageModel.fromJson(decodedResponse);
        if (model.status == false) {
          Loggers.error(model.message);
        }
        if (fromJson != null) {
          return fromJson(decodedResponse);
        }

        // If no `fromJson` is provided, return the raw response
        return decodedResponse as T;
      } else if (response.statusCode == 404) {
        Loggers.error('Please check baseURL in const.dart file');
        throw Exception("URL Error: ${response.statusCode} - $url");
      } else {
        final errorBody = response.body;
        final errorMessage = _extractErrorMessage(errorBody);
        Loggers.error(errorMessage);
        // Handle HTTP errors
        throw Exception(
            "HTTP Error: ${response.statusCode} - ${response.reasonPhrase}");
      }
    } on HttpException {
      throw Exception('Could not connect to the server');
    } on FormatException catch (e) {
      Loggers.error("Invalid JSON format: ${e.source}");
      throw Exception("Invalid JSON format: ${e.message}");
    } on Exception catch (e) {
      Loggers.error("Unexpected error: $e");
      rethrow;
    } finally {
      _cleanupClient(cancelToken, client);
    }
  }

  Future<T> multiPartCallApi<T>({
    required String url,
    Map<String, dynamic>? param,
    required Map<String, List<XFile?>> filesMap,
    Function(double percentage)? onProgress,
    CancelToken? cancelToken,
    T Function(Map<String, dynamic> json)? fromJson,
  }) async {
    // 同上：无取消需求时复用共享连接池
    final client = cancelToken != null ? http.Client() : _client;
    if (cancelToken != null) {
      _activeClients[cancelToken] = client;
    }

    final request = MultipartRequest(
      'POST',
      Uri.parse(url),
      onProgress: (bytes, totalBytes) {
        if (onProgress != null) {
          onProgress(bytes / totalBytes);
        }
      },
    );

    Map<String, String> params = {};
    param?.removeWhere(
      (key, value) => value == null,
    );
    param?.forEach((key, value) {
      params[key] = "$value";
    });

    request.fields.addAll(params);
    request.headers.addAll(header);

    filesMap.forEach((keyName, files) {
      for (var xFile in files) {
        if (xFile != null && xFile.path.isNotEmpty) {
          final file = File(xFile.path);
          final multipartFile = http.MultipartFile(
            keyName,
            file.readAsBytes().asStream(),
            file.lengthSync(),
            filename: xFile.name,
          );
          request.files.add(multipartFile);
        }
      }
    });

    Loggers.info("URL: $url");
    Loggers.info("Headers: ${JsonEncoder.withIndent('  ').convert(header)}");
    Loggers.info(
        "Parameters: ${params.isEmpty ? "Empty" : JsonEncoder.withIndent('  ').convert(params)}");

    try {
      // 上传大文件耗时较长，超时放宽到 5 分钟，但同样不能没有超时
      final responseStream =
          await client.send(request).timeout(const Duration(seconds: 300));

      if (cancelToken?.isCancelled ?? false) {
        Loggers.warning("Request cancelled: $url");
        throw Exception('Request was cancelled');
      }

      final responseStr = await responseStream.stream
          .bytesToString()
          .timeout(const Duration(seconds: 300));

      if (responseStream.statusCode >= 200 && responseStream.statusCode < 300) {
        final decodedResponse = jsonDecode(responseStr) as Map<String, dynamic>;
        final prettyString =
            const JsonEncoder.withIndent('  ').convert(decodedResponse);
        Loggers.info(prettyString);

        // Use the provided `fromJson` function to parse the response
        if (fromJson != null) {
          return fromJson(decodedResponse);
        }

        // If no `fromJson` is provided, return the raw response
        return decodedResponse as T;
      } else if (responseStream.statusCode == 404) {
        Loggers.error('Please check baseURL in const.dart file');
        throw Exception("URL Error: ${responseStream.statusCode} - $url");
      } else {
        final errorMessage = _extractErrorMessage(responseStr);
        Loggers.error(errorMessage);
        throw Exception(
            "HTTP Error: ${responseStream.statusCode} - ${responseStream.reasonPhrase}");
      }
    } on HttpException {
      throw Exception('Could not connect to the server');
    } on FormatException catch (e) {
      Loggers.error("Invalid JSON format: ${e.message}");
      throw Exception("Invalid JSON format: ${e.message}");
    } on Exception catch (e) {
      Loggers.error("Unexpected error: $e");
      rethrow;
    } finally {
      _cleanupClient(cancelToken, client);
    }
  }

  /// 只有带 cancelToken 的独立 client 才需要关闭；共享 client 保持存活以复用连接
  void _cleanupClient(CancelToken? cancelToken, http.Client client) {
    if (cancelToken != null) {
      _activeClients.remove(cancelToken);
      client.close();
    }
  }

  String _extractErrorMessage(String responseBody) {
    final regex = RegExp(
      r'<!--\s*(.*?)\s*#0 ', // Matches everything between <!-- and #0
      dotAll: true,
    );
    final match = regex.firstMatch(responseBody);
    return match?.group(1)?.trim() ??
        "Unknown error occurred: ${_shorten(responseBody)}";
  }

  /// Shortens the response body if no specific error is found
  String _shorten(String responseBody) {
    const maxLength = 100;
    return responseBody.length > maxLength
        ? "${responseBody.substring(0, maxLength)}..."
        : responseBody;
  }
}
