import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HowItWorksSection extends StatelessWidget {
  final AnimationController animationController;
  final Animation<double> fadeAnimation;

  const HowItWorksSection({
    Key? key,
    required this.animationController,
    required this.fadeAnimation,
  }) : super(key: key);

  final List<_StepInfo> steps = const [
    _StepInfo(
      icon: Icons.location_on_rounded,
      heroTag: 'step1Icon',
      title: 'Set Your Location',
      subtitle: 'Tell us where to deliver the fuel',
    ),
    _StepInfo(
      icon: Icons.local_gas_station_rounded,
      heroTag: 'step2Icon',
      title: 'Choose Fuel Type',
      subtitle: 'Select petrol or diesel as per your need',
    ),
    _StepInfo(
      icon: Icons.payment_rounded,
      heroTag: 'step3Icon',
      title: 'Make Payment',
      subtitle: 'Pay securely via UPI, card or wallet',
    ),
    _StepInfo(
      icon: Icons.local_shipping_rounded,
      heroTag: 'step4Icon',
      title: 'Fuel Delivered',
      subtitle: 'Get fuel delivered safely to your vehicle',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: animationController,
                curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
              ),
            ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.shade50, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How It Works',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 20),
              ...steps.asMap().entries.map((entry) {
                final index = entry.key;
                final step = entry.value;
                return _AnimatedLuxuryStepCard(
                  step: step,
                  animationController: animationController,
                  index: index,
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepInfo {
  final IconData icon;
  final String heroTag;
  final String title;
  final String subtitle;

  const _StepInfo({
    required this.icon,
    required this.heroTag,
    required this.title,
    required this.subtitle,
  });
}

class _AnimatedLuxuryStepCard extends StatefulWidget {
  final _StepInfo step;
  final AnimationController animationController;
  final int index;

  const _AnimatedLuxuryStepCard({
    Key? key,
    required this.step,
    required this.animationController,
    required this.index,
  }) : super(key: key);

  @override
  State<_AnimatedLuxuryStepCard> createState() =>
      _AnimatedLuxuryStepCardState();
}

class _AnimatedLuxuryStepCardState extends State<_AnimatedLuxuryStepCard>
    with SingleTickerProviderStateMixin {
  bool _isHovering = false;
  late AnimationController _iconPulseController;

  @override
  void initState() {
    super.initState();
    _iconPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
      lowerBound: 0.95,
      upperBound: 1.05,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _iconPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: widget.animationController,
      curve: Interval(0.6 + 0.1 * widget.index, 1.0, curve: Curves.easeOut),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(-0.4, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.green),
            boxShadow: [
              BoxShadow(
                color: Colors.green,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: Colors.white.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    ScaleTransition(
                      scale: _iconPulseController,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: _isHovering
                                ? [
                                    Colors.deepOrange.shade300,
                                    Colors.deepOrange.shade600,
                                  ]
                                : [
                                    Colors.deepOrange.shade100,
                                    Colors.deepOrange.shade300,
                                  ],
                          ),
                          boxShadow: [
                            if (_isHovering)
                              BoxShadow(
                                color: Colors.green,
                                blurRadius: 12,
                                spreadRadius: 1,
                              ),
                          ],
                        ),
                        padding: const EdgeInsets.all(10),
                        child: Icon(
                          widget.step.icon,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.step.title,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.step.subtitle,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
