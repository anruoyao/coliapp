import 'dart:convert';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:untitled/common/managers/logger.dart';
import 'package:untitled/utilities/const.dart';

enum ShareKeys {
  user('user'),
  post('post'),
  reel('reel'),
  room('room');

  const ShareKeys(this.value);

  final String value;
}

class ShareManager {
  static var shared = ShareManager();
  var isListenerConfigured = false;

  void listen(Function(ShareKeys key, int value) completion) {
    if (isListenerConfigured) return;
    isListenerConfigured = true;
    AppLinks().uriLinkStream.listen((uri) {
      Loggers.info('Share Link Opened: $uri ${uri.pathSegments} ${uri.path}');
      if (uri.pathSegments.isNotEmpty) {
        var encoded = uri.pathSegments.last;
        Loggers.success(encoded);
        var decoded = safeBase64Decode(encoded);

        var values = decoded.split('_');
        completion(
            ShareKeys.values
                .firstWhere((element) => element.value == values.first),
            int.parse(values.last));
      }
    });
  }

  void shareTheContent({required ShareKeys key, required int value}) {
    final encoded = safeBase64Encode('${key.value}_$value');
    final url = '${baseURL}s/$encoded';
    final context = Get.context!;

    final box = context.findRenderObject() as RenderBox?;
    final origin = box!.localToGlobal(Offset.zero) & box.size;

    // Share.share("$url", sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size);
    SharePlus.instance
        .share(ShareParams(uri: Uri.parse(url), sharePositionOrigin: origin));
  }

  String safeBase64Encode(String input) {
    // Encode normally
    String encoded = base64.encode(utf8.encode(input));

    // Remove all '=' padding at the end
    return encoded.replaceAll('=', '');
  }

  String safeBase64Decode(String input) {
    // Remove all whitespace
    input = input.trim();

    // Remove any invalid padding (> 2 '=' at end)
    input = input.replaceAll(RegExp(r'=+$'), '');

    // Add correct padding (base64 should be multiple of 4)
    while (input.length % 4 != 0) {
      input += '=';
    }

    return utf8.decode(base64.decode(input));
  }
}
