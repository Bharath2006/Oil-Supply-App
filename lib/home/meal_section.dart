import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'meal_item.dart';

class MealTabs extends StatefulWidget {
  final AnimationController animationController;
  final List<Map<String, dynamic>> mealTypes;

  const MealTabs({
    Key? key,
    required this.animationController,
    required this.mealTypes,
  }) : super(key: key);

  @override
  State<MealTabs> createState() => _MealTabsState();
}

class _MealTabsState extends State<MealTabs>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    try {
      _tabController = TabController(
        length: widget.mealTypes.length,
        vsync: this,
      );
      _tabController.addListener(() {
        if (_tabController.indexIsChanging) {
          setState(() => _selectedIndex = _tabController.index);
        }
      });
    } catch (e) {
      debugPrint('Error initializing TabController: $e');
    }
  }

  @override
  void dispose() {
    try {
      _tabController.dispose();
    } catch (e) {
      debugPrint('Error disposing TabController: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final scaleFactor = screenWidth / 375;
    final textScale = scaleFactor.clamp(0.85, 1.2);

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 12 * scaleFactor),
          child: Column(
            children: [
              Text(
                "Menu",
                style: TextStyle(
                  fontSize: 30 * textScale,
                  fontWeight: FontWeight.w700,
                  color: Colors.green.shade800,
                  shadows: [
                    Shadow(
                      color: Colors.green.withOpacity(0.2),
                      blurRadius: 4,
                      offset: Offset(0, 2 * scaleFactor),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 4 * scaleFactor),
              Container(
                height: 3 * scaleFactor,
                width: 120 * scaleFactor,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade400, Colors.green.shade200],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(2 * scaleFactor),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 70 * scaleFactor,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(
              horizontal: 12 * scaleFactor,
              vertical: 10 * scaleFactor,
            ),
            itemCount: widget.mealTypes.length,
            separatorBuilder: (_, __) => SizedBox(width: 14 * scaleFactor),
            itemBuilder: (context, index) {
              final meal = widget.mealTypes[index];
              final isSelected = index == _selectedIndex;

              return GestureDetector(
                onTap: () async {
                  try {
                    await HapticFeedback.selectionClick();
                    if (index >= 0 && index < _tabController.length) {
                      _tabController.animateTo(index);
                      setState(() => _selectedIndex = index);
                    }
                  } catch (e) {
                    debugPrint('Error handling tab tap: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Something went wrong. Please try again.',
                        ),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutExpo,
                  padding: EdgeInsets.symmetric(
                    horizontal: 18 * scaleFactor,
                    vertical: 10 * scaleFactor,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22 * scaleFactor),
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [
                              Colors.green.shade400,
                              Colors.orangeAccent.shade200,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.7),
                              Colors.white.withOpacity(0.4),
                            ],
                          ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 10 * scaleFactor,
                              offset: Offset(0, 4 * scaleFactor),
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    children: [
                      AnimatedScale(
                        scale: isSelected ? 1.3 : 1.0,
                        duration: const Duration(milliseconds: 400),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            meal['icon'],
                            key: ValueKey(isSelected),
                            color: isSelected ? Colors.white : Colors.green,
                            size: 20 * scaleFactor,
                          ),
                        ),
                      ),
                      SizedBox(width: 8 * scaleFactor),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 16 * textScale,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : Colors.green.shade700,
                        ),
                        child: Text(meal['name']),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(
          height: 280 * scaleFactor,
          child: TabBarView(
            controller: _tabController,
            children: widget.mealTypes.map((meal) {
              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 8 * scaleFactor,
                  vertical: 4 * scaleFactor,
                ),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: meal['items'].length,
                  separatorBuilder: (_, __) =>
                      SizedBox(width: 12 * scaleFactor),
                  itemBuilder: (context, index) {
                    final item = meal['items'][index];
                    return MealItem(
                      item: item,
                      index: index,
                      animationController: widget.animationController,
                    );
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
