import 'package:flutter/material.dart';

class HeroBanner extends StatelessWidget {
  final AnimationController animationController;
  final Animation<double> fadeAnimation;

  const HeroBanner({
    Key? key,
    required this.animationController,
    required this.fadeAnimation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(animationController),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Hero(
              tag: 'hero-banner',
              child: Image.asset('assets/test/t.jpg', fit: BoxFit.cover),
            ),
          ),
        ),
      ),
    );
  }
}