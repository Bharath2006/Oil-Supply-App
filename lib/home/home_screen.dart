import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'about_section.dart';
import 'contact_details_section.dart';
import 'hero_banner.dart';
import 'how_it_works_section.dart';
import 'meal_section.dart';
import 'upcoming_orders_section.dart';
import 'Why_Bunksy.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late ScrollController _scrollController;

  bool _showMealsFab = false;
  final GlobalKey _mealSectionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_handleScroll);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOutBack),
      ),
    );

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 15,
    ).chain(CurveTween(curve: Curves.elasticOut)).animate(_shakeController);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward().catchError(
        (e) => debugPrint('AnimationController error: $e'),
      );
    });

    FirebaseInAppMessaging.instance.setMessagesSuppressed(false).catchError((
      e,
    ) {
      debugPrint('Failed to enable in-app messaging: $e');
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _animationController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    try {
      final context = _mealSectionKey.currentContext;
      if (context != null) {
        final box = context.findRenderObject() as RenderBox?;
        if (box != null) {
          final mealOffset = box.localToGlobal(Offset.zero).dy;
          final triggerOffset = mealOffset + 150;
          if (_scrollController.offset > triggerOffset && !_showMealsFab) {
            setState(() => _showMealsFab = true);
          } else if (_scrollController.offset <= triggerOffset &&
              _showMealsFab) {
            setState(() => _showMealsFab = false);
          }
        }
      }
    } catch (e) {
      debugPrint('Scroll detection error: $e');
    }
  }

  Future<void> _scrollToMealSection() async {
    try {
      HapticFeedback.mediumImpact();
      final context = _mealSectionKey.currentContext;
      if (context != null) {
        await Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeInOutCubic,
        );
        await Future.delayed(const Duration(milliseconds: 100));
        _shakeController
            .forward(from: 0)
            .catchError((e) => debugPrint('Shake animation error: $e'));
        await FirebaseAnalytics.instance.logEvent(name: 'show_meal_promo');
      }
    } catch (e) {
      debugPrint('Scroll to meal section failed: $e');
    }
  }

  final List<Map<String, dynamic>> _mealTypes = const [
    {
      'name': 'Petrol',
      'icon': Icons.local_gas_station,
      'items': [
        {
          'name': 'Petrol',
          'price': 90,
          'description':
              'High-octane fuel suitable for most two-wheelers and cars.',
          'image': 'assets/Fuels/petrol.jpeg',
          'type': 'Petrol',
          'benefit': 'Ensures smooth engine performance and better mileage.',
        },
      ],
    },
    {
      'name': 'Diesel',
      'icon': Icons.fire_truck,
      'items': [
        {
          'name': 'Diesel',
          'price': 85,
          'description':
              'Efficient fuel for commercial vehicles and long-distance travel.',
          'image': 'assets/Fuels/diesel.jpg',
          'type': 'Diesel',
          'benefit':
              'Offers high torque and fuel economy for heavy-duty engines.',
        },
      ],
    },
    {
      'name': 'Engine Oil',
      'icon': Icons.build_circle,
      'items': [
        {
          'name': 'Engine Oil',
          'price': 250,
          'description':
              'Premium lubricant for optimal engine health and longevity.',
          'image': 'assets/Fuels/oil.jpg',
          'type': 'Engine Oil',
          'benefit': 'Reduces wear and tear, improves engine efficiency.',
        },
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = screenWidth / 375;
    final textScale = scaleFactor.clamp(0.85, 1.2);

    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 4,
        toolbarHeight: 56 * scaleFactor,
        titleSpacing: 16 * scaleFactor,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green, Colors.orangeAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Text(
              'Tiffin Service',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 22 * textScale,
                color: Colors.white,
              ),
            ),
          ),
        ),
        actions: [
          if (user != null)
            FadeTransition(
              opacity: _fadeAnimation,
              child: IconButton(
                icon: Icon(
                  Icons.logout,
                  color: Colors.white,
                  size: 24 * scaleFactor,
                ),
                onPressed: () async {
                  try {
                    await FirebaseAuth.instance.signOut();
                  } catch (e) {
                    debugPrint('Logout failed: $e');
                  }
                },
                tooltip: 'Logout',
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            UpcomingOrdersSection(
              animationController: _animationController,
              fadeAnimation: _fadeAnimation,
              userId: user?.uid,
            ),
            HeroBanner(
              animationController: _animationController,
              fadeAnimation: _fadeAnimation,
            ),
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, -_shakeAnimation.value * scaleFactor),
                  child: child!,
                );
              },
              child: Container(
                key: _mealSectionKey,
                margin: EdgeInsets.symmetric(vertical: 12 * scaleFactor),
                child: MealTabs(
                  animationController: _animationController,
                  mealTypes: _mealTypes,
                ),
              ),
            ),
            HowItWorksSection(
              animationController: _animationController,
              fadeAnimation: _fadeAnimation,
            ),
            SizedBox(height: 16 * scaleFactor),
            AboutSection(
              fadeAnimation: _fadeAnimation,
              scaleAnimation: _scaleAnimation,
            ),
            WhyOrderSection(
              fadeAnimation: _fadeAnimation,
              scaleAnimation: _scaleAnimation,
            ),
            ContactDetailsSection(
              fadeAnimation: _fadeAnimation,
              scaleAnimation: _scaleAnimation,
            ),
            SizedBox(height: 24 * scaleFactor),
          ],
        ),
      ),
      floatingActionButton: AnimatedOpacity(
        opacity: _showMealsFab ? 1 : 0,
        duration: const Duration(milliseconds: 300),
        child: AnimatedScale(
          scale: _showMealsFab ? 1 : 0,
          duration: const Duration(milliseconds: 300),
          child: FloatingActionButton.extended(
            backgroundColor: Colors.green,
            icon: Icon(
              Icons.fastfood,
              color: Colors.white,
              size: 24 * scaleFactor,
            ),
            label: Text(
              'Bunk',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16 * textScale,
              ),
            ),
            onPressed: _scrollToMealSection,
          ),
        ),
      ),
    );
  }
}
