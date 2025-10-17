import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../order/order_model.dart';
import 'order_card.dart';

class UpcomingOrdersSection extends StatelessWidget {
  final AnimationController animationController;
  final Animation<double> fadeAnimation;
  final String? userId;

  const UpcomingOrdersSection({
    super.key,
    required this.animationController,
    required this.fadeAnimation,
    this.userId,
  });

  DateTime get _today => DateTime.now();
  DateTime get _tomorrow => DateTime.now().add(const Duration(days: 1));

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isBefore(DateTime a, DateTime b) {
    return a.isBefore(
      DateTime(b.year, b.month, b.day).add(const Duration(days: 1)),
    );
  }

  bool _isAfter(DateTime a, DateTime b) {
    return a.isAfter(
      DateTime(b.year, b.month, b.day).subtract(const Duration(days: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) return const SizedBox.shrink();

    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(-0.5, 0), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: animationController,
                curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
              ),
            ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('orders')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return const SizedBox.shrink();
            if (!snapshot.hasData) return const CircularProgressIndicator();

            final orders = snapshot.data!.docs
                .map(
                  (doc) => FoodOrder.fromMap({
                    ...doc.data() as Map<String, dynamic>,
                    'id': doc.id,
                  }),
                )
                .toList();

            final upcoming = <Map<String, dynamic>>[];

            for (var order in orders) {
              final selectedDates = order.selectedDates ?? [];

              if (selectedDates.isNotEmpty) {
                for (var d in selectedDates) {
                  if (_isSameDate(d, _today) || _isSameDate(d, _tomorrow)) {
                    upcoming.add({'order': order, 'date': d});
                  }
                }
              } else {
                if (!_isBefore(_today, order.startDate) &&
                    !_isAfter(_today, order.endDate)) {
                  upcoming.add({'order': order, 'date': _today});
                }
                if (!_isBefore(_tomorrow, order.startDate) &&
                    !_isAfter(_tomorrow, order.endDate)) {
                  upcoming.add({'order': order, 'date': _tomorrow});
                }
                            }
            }

            upcoming.sort(
              (a, b) =>
                  (a['date'] as DateTime).compareTo(b['date'] as DateTime),
            );

            if (upcoming.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    'Your Upcoming Orders\n'
                    '(${DateFormat('dd MMM').format(_today)} & ${DateFormat('dd MMM').format(_tomorrow)})',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                SizedBox(
                  height: 220,
                  child: PageView.builder(
                    controller: PageController(viewportFraction: 0.8),
                    itemCount: upcoming.length,
                    itemBuilder: (context, index) {
                      final item = upcoming[index];
                      final FoodOrder ord = item['order'];
                      final DateTime date = item['date'];
                      return AnimatedBuilder(
                        animation: animationController,
                        builder: (context, child) {
                          final animationValue = Curves.easeOut.transform(
                            Interval(
                              0.3 + 0.1 * index,
                              0.8,
                              curve: Curves.easeOut,
                            ).transform(animationController.value),
                          );

                          return Transform(
                            transform: Matrix4.identity()
                              ..translate(0.0, 50 * (1 - animationValue))
                              ..scale(animationValue),
                            alignment: Alignment.center,
                            child: Opacity(
                              opacity: animationValue,
                              child: child,
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: OrderCard(order: ord, date: date),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}