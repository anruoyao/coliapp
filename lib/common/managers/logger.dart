import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

class Loggers {
  static void info(Object? msg) {
    if (kDebugMode) developer.log('$msg', name: 'INFO');
  }

  static void success(Object? msg) {
    if (kDebugMode) developer.log('✅✅✅: $msg', name: 'SUCCESS');
  }

  static void warning(Object? msg) {
    if (kDebugMode) developer.log('⚠️⚠️⚠️: $msg', name: 'WARNING');
  }

  static void error(Object? msg) {
    if (kDebugMode) developer.log('🔴🔴🔴: $msg', name: 'ERROR');
  }
}
