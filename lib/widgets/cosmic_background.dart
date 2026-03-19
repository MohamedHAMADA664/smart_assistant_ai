import 'package:flutter/material.dart';

class CosmicBackground extends StatelessWidget {
  const CosmicBackground({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
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
      child: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              color: Colors.black.withOpacity(0.08),
            ),
            child,
          ],
        ),
      ),
    );
  }
}
