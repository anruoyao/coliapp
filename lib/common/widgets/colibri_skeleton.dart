import 'package:flutter/material.dart';
import 'package:untitled/utilities/const.dart';

/// Shared animated post skeleton used while timeline-like lists are loading.
class ColibriSkeletonPosts extends StatefulWidget {
  final Widget? leading;
  final Future<void> Function()? onRefresh;

  const ColibriSkeletonPosts({super.key, this.leading, this.onRefresh});

  @override
  State<ColibriSkeletonPosts> createState() => _ColibriSkeletonPostsState();
}

class _ColibriSkeletonPostsState extends State<ColibriSkeletonPosts>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: (widget.leading == null ? 0 : 1) + 5,
          separatorBuilder: (_, __) => const Divider(
            height: 1,
            thickness: 1,
            color: cLightBg,
          ),
          itemBuilder: (_, index) {
            final phase = (_controller.value + index * 0.12) % 1;
            if (widget.leading != null && index == 0) {
              return widget.leading!;
            }
            return ColibriSkeletonPost(phase: phase);
          },
        );
      },
    );
    if (widget.onRefresh == null) return list;
    return RefreshIndicator(
      color: cPrimary,
      onRefresh: widget.onRefresh!,
      child: list,
    );
  }
}

class ColibriSkeletonPost extends StatelessWidget {
  final double phase;

  const ColibriSkeletonPost({super.key, required this.phase});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ColibriSkeletonBlock(
                width: 42,
                height: 42,
                phase: phase,
                radius: 21,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ColibriSkeletonBlock(width: 112, height: 10, phase: phase),
                  const SizedBox(height: 8),
                  ColibriSkeletonBlock(width: 76, height: 8, phase: phase),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ColibriSkeletonBlock(
            width: double.infinity,
            height: 11,
            phase: phase,
          ),
          const SizedBox(height: 9),
          FractionallySizedBox(
            widthFactor: 0.82,
            child: ColibriSkeletonBlock(
              width: double.infinity,
              height: 11,
              phase: phase,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ColibriSkeletonBlock(width: 44, height: 9, phase: phase),
              const SizedBox(width: 24),
              ColibriSkeletonBlock(width: 44, height: 9, phase: phase),
              const SizedBox(width: 24),
              ColibriSkeletonBlock(width: 44, height: 9, phase: phase),
            ],
          ),
        ],
      ),
    );
  }
}

class ColibriSkeletonBlock extends StatelessWidget {
  final double width;
  final double height;
  final double phase;
  final double radius;

  const ColibriSkeletonBlock({
    super.key,
    required this.width,
    required this.height,
    required this.phase,
    this.radius = 5,
  });

  @override
  Widget build(BuildContext context) {
    final shift = phase * 2 - 1;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(shift - 1, 0),
              end: Alignment(shift + 1, 0),
              colors: const [
                Color(0xFFE9EBEF),
                Color(0xFFF7F8FA),
                Color(0xFFE9EBEF),
              ],
              stops: const [0.35, 0.5, 0.65],
            ),
          ),
        ),
      ),
    );
  }
}
