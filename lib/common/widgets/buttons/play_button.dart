import 'package:flutter/material.dart';
import 'package:untitled/utilities/const.dart';

class PlayButton extends StatelessWidget {
  const PlayButton({super.key});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: cBlack.withValues(alpha: 0.5),
      foregroundColor: cWhite,
      child: const Icon(
        Icons.play_arrow_rounded,
        size: 28,
      ),
    );
  }
}
