import 'dart:async';

import 'package:flutter/material.dart';

class MyDebouncer {
  static var shared = MyDebouncer();
  final int milliseconds = 500;
  Timer? _timer;

  void run(VoidCallback action, {int? milliseconds}) {
    _timer?.cancel();
    _timer = Timer(
      Duration(milliseconds: milliseconds ?? this.milliseconds),
      () {
        cancel();
        action();
      },
    );
  }

  void cancel() {
    _timer?.cancel();
  }

  bool get isActive => _timer?.isActive ?? false;
}
