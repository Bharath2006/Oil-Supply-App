import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_custom_clippers/flutter_custom_clippers.dart';

class AboutSection extends StatefulWidget {
  final Animation<double> fadeAnimation;
  final Animation<double> scaleAnimation;

  const AboutSection({
    Key? key,
    required this.fadeAnimation,
    required this.scaleAnimation,
  }) : super(key: key);

  @override
  State<AboutSection> createState() => _AboutSectionState();
}

class _AboutSectionState extends State<AboutSection>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _imageZoomAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _textFadeAnimation;

  late AnimationController _heroIconController;
  late Animation<double> _heroIconScale;
  late Animation<double> _heroIconRotation;

  List<bool> _iconSelected = [false, false, false];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _imageZoomAnimation = Tween<double>(
      begin: 1.1,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _textFadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _heroIconController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _heroIconScale = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _heroIconController, curve: Curves.easeInOut),
    );

    _heroIconRotation = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(parent: _heroIconController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _heroIconController.dispose();
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
              color: Colors.green,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon(
    int index,
    IconData iconDefault,
    IconData iconSelected,
    String text,
    double iconSize,
    double fontSize,
    double horizontalPadding,
    double verticalPadding,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _iconSelected[index] = !_iconSelected[index];
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        decoration: BoxDecoration(
          color: _iconSelected[index] ? Colors.green : Colors.transparent,
          borderRadius: BorderRadius.circular(_iconSelected[index] ? 12 : 8),
          boxShadow: _iconSelected[index]
              ? [
                  BoxShadow(
                    color: Colors.green,
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                _iconSelected[index] ? iconSelected : iconDefault,
                key: ValueKey<bool>(_iconSelected[index]),
                size: iconSize,
                color: _iconSelected[index]
                    ? Colors.green
                    : Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: fontSize,
                  color: _iconSelected[index]
                      ? Colors.green
                      : Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
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

    double titleFontSize = screenWidth > 600 ? 26 : 22;
    double textFontSize = screenWidth > 600 ? 16 : 14;
    double subTitleFontSize = screenWidth > 600 ? 18 : 16;
    double iconSize = screenWidth > 600 ? 24 : (screenWidth < 350 ? 18 : 20);
    double imageHeight = screenWidth > 600 ? 220 : 160;
    double horizontalPadding = screenWidth > 600 ? 24 : 16;

    if (screenWidth < 350) {
      textFontSize -= 1;
      subTitleFontSize -= 1;
    }

    return Column(
      children: [
        // ✅ Hero banner
        Container(
          color: Colors.deepOrange.shade50,
          padding: EdgeInsets.only(
            top: 4,
            bottom: 8,
            left: horizontalPadding,
            right: horizontalPadding,
          ),

          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bunksy',
                      style: GoogleFonts.poppins(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w700,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '"High-quality fuel and essential delivery solutions for everyone – from daily drivers to fleet operators.',
                      style: GoogleFonts.poppins(
                        fontSize: textFontSize,
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () {},
                      child: Text(
                        'Order Now',
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ScaleTransition(
                scale: _heroIconScale,
                child: RotationTransition(
                  turns: _heroIconRotation,
                  child: Icon(Icons.fastfood, size: 80, color: Colors.green),
                ),
              ),
            ],
          ),
        ),
        ClipPath(
          clipper: WaveClipperOne(),
          child: Container(height: 60, color: Colors.deepOrange.shade100),
        ),
        _buildSectionTitle('About Bunksy', titleFontSize),
        FadeTransition(
          opacity: widget.fadeAnimation,
          child: ScaleTransition(
            scale: widget.scaleAnimation,
            child: Container(
              margin: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedBuilder(
                        animation: _imageZoomAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _imageZoomAnimation.value,
                            child: Container(
                              width: double.infinity,
                              height: imageHeight,
                              color: Colors.deepOrange.shade100,
                              child: Icon(
                                Icons.restaurant_menu,
                                size: 80,
                                color: Colors.green,
                              ),
                            ),
                          );
                        },
                      ),
                      FadeTransition(
                        opacity: _textFadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Fuel Delivered. Anytime. Anywhere.',
                                  style: GoogleFonts.poppins(
                                    fontSize: subTitleFontSize,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Fuelzy delivers clean fuel right to your vehicle — perfect for daily commuters, road trippers, fleet managers, or anyone tired of fuel station queues.',
                                  style: GoogleFonts.poppins(
                                    fontSize: textFontSize,
                                    color: Colors.grey.shade700,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    _buildAnimatedIcon(
                                      0,
                                      Icons.local_gas_station_outlined,
                                      Icons.local_gas_station,
                                      'Convenient',
                                      iconSize,
                                      textFontSize - 1,
                                      8,
                                      6,
                                    ),
                                    const SizedBox(width: 12),
                                    _buildAnimatedIcon(
                                      1,
                                      Icons.lock_clock_outlined,
                                      Icons.lock_clock,
                                      '24/7 Service',
                                      iconSize,
                                      textFontSize - 1,
                                      8,
                                      6,
                                    ),
                                    const SizedBox(width: 12),
                                    _buildAnimatedIcon(
                                      2,
                                      Icons.verified_outlined,
                                      Icons.verified,
                                      'Trusted',
                                      iconSize,
                                      textFontSize - 1,
                                      8,
                                      6,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        ClipPath(
          clipper: WaveClipperOne(flip: true, reverse: true),
          child: Container(height: 60, color: Colors.deepOrange.shade100),
        ),
      ],
    );
  }
}
