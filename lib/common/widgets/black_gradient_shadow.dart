import 'package:flutter/material.dart';

class BlackGradientShadow extends StatelessWidget {
  const BlackGradientShadow({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 300,
      alignment: Alignment.bottomCenter,
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
            begin: Alignment.topCenter,
            end: AlignmentDirectional.bottomCenter),
      ),
    );
  }
}
