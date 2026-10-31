import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:untitled/common/extensions/image_extension.dart';
import 'package:untitled/common/managers/haptic_manager.dart';
import 'package:untitled/utilities/const.dart';
import 'package:untitled/utilities/filters.dart';

class ColorFilterPageViewList extends StatefulWidget {
  final Function(int intdex) onPageChanged;
  final String? image;
  final PageController pageController;

  ColorFilterPageViewList({
    super.key,
    required this.onPageChanged,
    this.image,
    required this.pageController, // Set default initial index
  });

  @override
  State<ColorFilterPageViewList> createState() =>
      _ColorFilterPageViewListState();
}

class _ColorFilterPageViewListState extends State<ColorFilterPageViewList> {
  @override
  void initState() {
    super.initState();
    // Initial stage value refresh
    Future.delayed(const Duration(milliseconds: 1), () {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    double size = 80;
    return SizedBox(
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PageView.builder(
            controller: widget.pageController,
            onPageChanged: (value) {
              HapticManager.shared.light();
              widget.onPageChanged(value);
            },
            itemCount: filters.length,
            itemBuilder: (context, index) {
              Filters filter = filters[index];
              return AnimatedBuilder(
                animation: widget.pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (widget.pageController.position.haveDimensions) {
                    value = widget.pageController.page! - index;
                  } else {
                    value = 0.0 - index;
                  }

                  value = (1 - (value.abs())).clamp(0.7, 1.0);

                  return GestureDetector(
                    onTap: () {
                      widget.pageController.animateToPage(index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.linear);
                      widget.onPageChanged(index);
                    },
                    child: Center(
                      child: Transform.scale(
                        scale: value,
                        child: Container(
                          width: size - 10,
                          height: size - 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: widget.image == null
                                ? DecorationImage(
                                    image: AssetImage(
                                      MyImages.structure,
                                    ),
                                    fit: BoxFit.cover,
                                    colorFilter: filter.colorFilter.isNotEmpty
                                        ? ColorFilter.matrix(filter.colorFilter)
                                        : null)
                                : _decorationImage(filter),
                            border: Border.all(color: Colors.transparent),
                          ),
                          child: widget.image == null
                              ? ClipOval(
                                  child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                          sigmaX: 1.2, sigmaY: 1.2),
                                      child: Container()),
                                )
                              : const SizedBox(),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          IgnorePointer(
            child: Container(
              height: size,
              width: size,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: cWhite, width: 5)),
            ),
          ),
        ],
      ),
    );
  }

  DecorationImage? _decorationImage(Filters filter) {
    return DecorationImage(
        image: FileImage(File(widget.image ?? '')),
        // Replace with actual image source if required
        colorFilter: filter.colorFilter.isNotEmpty
            ? ColorFilter.matrix(filter.colorFilter)
            : null,
        fit: BoxFit.cover);
  }
}
