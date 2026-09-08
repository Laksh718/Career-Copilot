import 'package:flutter/material.dart';
import 'textured_background.dart';

class AnimatedBg extends StatelessWidget {
  final Widget child;
  const AnimatedBg({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return TexturedBackground(child: child);
  }
}

