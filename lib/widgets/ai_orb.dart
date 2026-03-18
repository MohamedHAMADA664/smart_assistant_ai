import 'package:flutter/material.dart';

class AIOrb extends StatefulWidget {
  const AIOrb({super.key});

  @override
  State<AIOrb> createState() => _AIOrbState();
}

class _AIOrbState extends State<AIOrb> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        double glow = 30 + (_controller.value * 40);

        return Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [
                Color(0xff6a5cff),
                Color(0xff9c27ff),
                Color(0xff00e5ff),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withValues(alpha: 0.7),
                blurRadius: glow,
                spreadRadius: glow / 3,
              )
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
