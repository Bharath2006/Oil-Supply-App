import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';

class WhyOrderSection extends StatefulWidget {
  final Animation<double> fadeAnimation;
  final Animation<double> scaleAnimation;

  const WhyOrderSection({
    super.key,
    required this.fadeAnimation,
    required this.scaleAnimation,
  });

  @override
  State<WhyOrderSection> createState() => _WhyOrderSectionState();
}

class _WhyOrderSectionState extends State<WhyOrderSection>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _scaleAnimations;
  late List<AnimationController> _iconControllers;
  late List<ConfettiController> _confettiControllers;

  final List<bool> _iconActive = List.generate(4, (_) => false);

  final List<IconData> icons = [
    Icons.local_dining,
    Icons.attach_money,
    Icons.fitness_center,
    Icons.bubble_chart,
  ];

  final List<String> titles = [
    "Fuel at Your Doorstep",
    "Budget‑Friendly Refills",
    "Fleet‑Ready Service",
    "Quick Fill Vibes",
  ];

  final List<String> subtitles = [
    "Skip the petrol bunk – get clean fuel delivered right where you need it.",
    "Flexible delivery plans that save time and money for every driver.",
    "Reliable fuel supply for businesses, fleets, and logistics teams on the move.",
    "Fast, on-demand refueling to keep your day rolling without the wait.",
  ];

  @override
  void initState() {
    super.initState();

    // Staggered card animations
    _controllers = List.generate(
      4,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 800),
      ),
    );

    _scaleAnimations = _controllers
        .map(
          (controller) =>
              CurvedAnimation(parent: controller, curve: Curves.easeOutBack),
        )
        .toList();

    _iconControllers = List.generate(
      4,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200),
        lowerBound: 0.95,
        upperBound: 1.15,
      ),
    )..forEach((c) => c.repeat(reverse: true));

    _confettiControllers = List.generate(
      4,
      (_) => ConfettiController(duration: const Duration(milliseconds: 500)),
    );

    _startStaggeredAnimations();
  }

  Future<void> _startStaggeredAnimations() async {
    for (int i = 0; i < _controllers.length; i++) {
      await Future.delayed(const Duration(milliseconds: 150));
      _controllers[i].forward();
    }
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var c in _iconControllers) {
      c.dispose();
    }
    for (var c in _confettiControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _buildSectionTitle(String title, double fontSize) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: FadeTransition(
        opacity: widget.fadeAnimation,
        child: ScaleTransition(
          scale: widget.scaleAnimation,
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: Colors.green.shade700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard(
    int index,
    double iconSize,
    double titleSize,
    double subtitleSize,
  ) {
    return ScaleTransition(
      scale: _scaleAnimations[index],
      child: GestureDetector(
        onTap: () {
          setState(() {
            _iconActive[index] = !_iconActive[index];
          });
          _confettiControllers[index].play();
        },
        child: Stack(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.green.shade100.withOpacity(0.4),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Row(
                    children: [
                      ScaleTransition(
                        scale: _iconControllers[index],
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: _iconActive[index]
                                  ? [
                                      Colors.green.shade400,
                                      Colors.green.shade700,
                                    ]
                                  : [
                                      Colors.green.shade100,
                                      Colors.green.shade300,
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _iconActive[index]
                                    ? Colors.green.withOpacity(0.4)
                                    : Colors.green.withOpacity(0.2),
                                blurRadius: _iconActive[index] ? 12 : 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Icon(
                            icons[index],
                            size: iconSize,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              titles[index],
                              style: GoogleFonts.poppins(
                                fontSize: titleSize,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitles[index],
                              style: GoogleFonts.poppins(
                                fontSize: subtitleSize,
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
            Positioned.fill(
              child: Align(
                alignment: Alignment.topRight,
                child: ConfettiWidget(
                  confettiController: _confettiControllers[index],
                  blastDirectionality: BlastDirectionality.explosive,
                  numberOfParticles: 12,
                  maxBlastForce: 15,
                  minBlastForce: 8,
                  emissionFrequency: 0.01,
                  gravity: 0.4,
                  colors: [Colors.deepOrange, Colors.green, Colors.amber],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    double titleFontSize = screenWidth > 600 ? 22 : 20;
    double iconSize = screenWidth > 600 ? 24 : 20;
    double cardTitleSize = screenWidth > 600 ? 16 : 15;
    double cardSubtitleSize = screenWidth > 600 ? 14 : 13;

    return Column(
      children: [
        _buildSectionTitle('Why Bunksy?', titleFontSize),
        FadeTransition(
          opacity: widget.fadeAnimation,
          child: ScaleTransition(
            scale: widget.scaleAnimation,
            child: Column(
              children: List.generate(
                icons.length,
                (index) => _buildGlassCard(
                  index,
                  iconSize,
                  cardTitleSize,
                  cardSubtitleSize,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
