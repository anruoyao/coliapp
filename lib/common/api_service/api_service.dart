import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:untitled/common/managers/logger.dart';

class CancelToken {
  bool _isCancelled = false;

  bool get isCancelled => _isCancelled;

  void cancel() {
    _isCancelled = true;
  }
}

class ApiService {
  static final shared = ApiService();

  /// 共享 client：复用 keep-alive 连接池。
  /// 此前每个请求都新建并关闭 client，跨境链路上每次都要完整 DNS+TCP+TLS 握手，
  /// 遇到丢包时握手重试可达数秒，是评论接口慢的主因。
  final http.Client _client = http.Client();

  final Map<CancelToken, http.Client> _activeClients = {};

  var header = {'apikey': '123'};

  Future<void> call({
    required String url,
    Map<String, dynamic>? param,
    CancelToken? cancelToken,
    required Function(Map<String, dynamic> response) completion,
  }) async {
    // 无取消需求时使用共享 client；带 cancelToken 时才用独立 client（目前无调用方）
    final client = cancelToken != null ? http.Client() : _client;
    if (cancelToken != null) {
      _activeClients[cancelToken] = client;
    }

    Map<String, String> params = {};
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
          Loggers.warning('API request cancelled');
        }
        throw Exception('Request was cancelled');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decodedResponse =
            jsonDecode(response.body) as Map<String, dynamic>;
        completion(decodedResponse);
      } else if (response.statusCode == 404) {
        Loggers.error('API request failed with HTTP 404');
        throw Exception('API request failed with HTTP 404');
      } else {
        Loggers.error('API request failed with HTTP ${response.statusCode}');
        throw Exception('API request failed with HTTP ${response.statusCode}');
      }
    } on HttpException {
      throw Exception('Could not connect to the server');
    } on FormatException {
      // Handle JSON decoding errors
      Loggers.error('API returned invalid JSON');
      throw Exception('API returned invalid JSON');
    } on Exception {
      Loggers.error('API request failed');
      rethrow;
    } finally {
      _cleanupClient(cancelToken, client);
    }
  }

  Future multiPartCallApi({
    required String url,
    Map<String, dynamic>? param,
    required Map<String, List<XFile?>> filesMap,
    Function(double percentage)? onProgress,
    CancelToken? cancelToken,
    required Function(Map<String, dynamic> response) completion,
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
      if (value is List) {
        for (int i = 0; i < value.length; i++) {
          params['$key[$i]'] = jsonEncode(value[i]);
        }
      } else {
        params[key] = "$value";
      }
    });

    request.fields.addAll(params);
    request.headers.addAll(header);
    request.headers.addAll({'ContentType': 'multipart/form-data'});

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

    try {
      // 上传大文件耗时较长，超时放宽到 5 分钟，但同样不能没有超时
      final responseStream =
          await client.send(request).timeout(const Duration(seconds: 300));

      if (cancelToken?.isCancelled ?? false) {
        Loggers.warning('API upload cancelled');
        throw Exception('Request was cancelled');
      }

      final responseStr = await responseStream.stream
          .bytesToString()
          .timeout(const Duration(seconds: 300));

      if (responseStream.statusCode >= 200 && responseStream.statusCode < 300) {
        final decodedResponse = jsonDecode(responseStr) as Map<String, dynamic>;
        // Use the provided `fromJson` function to parse the response
        completion(decodedResponse);
      } else if (responseStream.statusCode == 404) {
        Loggers.error('API request failed with HTTP 404');
        throw Exception('API request failed with HTTP 404');
      } else {
        Loggers.error(
            'API request failed with HTTP ${responseStream.statusCode}');
        throw Exception(
            'API request failed with HTTP ${responseStream.statusCode}');
      }
    } on HttpException {
      throw Exception('Could not connect to the server');
    } on FormatException {
      Loggers.error('API returned invalid JSON');
      throw Exception('API returned invalid JSON');
    } on Exception {
      Loggers.error('API request failed');
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

  Future<String?> downloadFile(String url, String fileName) async {
    try {
      var response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        Directory? directory = await (Platform.isAndroid
            ? getExternalStorageDirectory()
            : getApplicationDocumentsDirectory());
        String filePath = '${directory!.path}/$fileName';
        File file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        Loggers.success('File downloaded');
        return filePath;
      } else {
        Loggers.error("Failed to download file.");
        return null;
      }
    } catch (e) {
      Loggers.error("Download error: $e");
      return null;
    }
  }
}

class MultipartRequest extends http.MultipartRequest {
  MultipartRequest(
    super.method,
    super.url, {
    this.onProgress,
  });

  final void Function(int bytes, int totalBytes)? onProgress;

  @override
  http.ByteStream finalize() {
    final byteStream = super.finalize();
    final total = contentLength;
    int bytes = 0;

    final transformer = StreamTransformer<List<int>, List<int>>.fromHandlers(
      handleData: (data, sink) {
        bytes += data.length;
        if (onProgress != null) {
          onProgress!(bytes, total);
        }
        sink.add(data);
      },
    );

    return http.ByteStream(byteStream.transform(transformer));
  }
}
