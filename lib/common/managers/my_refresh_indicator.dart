import 'package:flutter/material.dart';
import 'package:untitled/utilities/const.dart';

class MyRefreshIndicator extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;
  final bool shouldRefresh;

  const MyRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
    this.shouldRefresh = true,
  });

  @override
  Widget build(BuildContext context) {
    if (shouldRefresh) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        color: cPrimary,
        backgroundColor: cBlack,
        triggerMode: RefreshIndicatorTriggerMode.anywhere,
        child: child,
      );
    } else {
      return child;
    }
  }
}
