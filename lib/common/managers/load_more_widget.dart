import 'dart:async';

import 'package:flutter/material.dart';
import 'package:untitled/common/managers/my_debouncer.dart';

/// return true is refresh success
///
/// return false or null is fail
class LoadMoreWidget extends StatefulWidget {
  final Future Function() loadMore;
  final Widget child;

  const LoadMoreWidget(
      {super.key, required this.loadMore, required this.child});

  @override
  State<LoadMoreWidget> createState() => _LoadMoreWidgetState();
}

class _LoadMoreWidgetState extends State<LoadMoreWidget> {
  bool isLoading = false;
  bool isApiCalledOneTime = false;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Ensure we are dealing with a vertical scroll notification
        if (notification is ScrollEndNotification) {
          isApiCalledOneTime = false;
          if (mounted) {
            setState(() {});
          }
        }
        if (notification is ScrollUpdateNotification &&
            notification.metrics.axis == Axis.vertical) {
          final metrics = notification.metrics;

          // Check if we are near the bottom of the scrollable area
          if (metrics.pixels >= metrics.maxScrollExtent - 50) {
            if (!isLoading) {
              MyDebouncer.shared.run(() {
                if (!isApiCalledOneTime) {
                  isLoading = true;
                  widget.loadMore().then((value) {
                    isLoading = false;
                    isApiCalledOneTime = true;
                    if (mounted) {
                      setState(() {});
                    }
                  });
                }
              });
            }
          }
        }

        return false; // Allow other listeners to handle the notification
      },
      child: widget.child,
    );
  }
}
