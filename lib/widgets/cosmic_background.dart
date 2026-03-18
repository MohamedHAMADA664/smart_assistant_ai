import 'package:flutter/material.dart';

class CosmicBackground extends StatelessWidget {
  final Widget child;

  const CosmicBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.3),
          radius: 1.2,
          colors: [
            Color(0xff1a1a2e),
            Color(0xff0f0f1a),
            Color(0xff000000),
          ],
        ),
      ),
      child: child,
    );
  }
}
