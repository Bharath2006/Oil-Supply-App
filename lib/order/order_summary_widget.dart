import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

class OrderSummaryWidget extends StatelessWidget {
  final List<String> selectedMeals;
  final String? mealType;
  final String plan;
  final DateTime startDate;
  final DateTime endDate;
  final List<DateTime>? selectedDates;
  final int basePricePerMeal;
  final double totalPrice;

  const OrderSummaryWidget({
    Key? key,
    required this.selectedMeals,
    this.mealType,
    required this.plan,
    required this.startDate,
    required this.endDate,
    this.selectedDates,
    required this.basePricePerMeal,
    required this.totalPrice,
  }) : super(key: key);

  int get daysCount {
    try {
      switch (plan) {
        case 'Weekly':
          return selectedDates?.length ?? 0;
        case 'Monthly':
          return 30;
        default:
          return 1;
      }
    } catch (e) {
      debugPrint('Error calculating daysCount: $e');
      return 1;
    }
  }

  String buildShareText() {
    try {
      final buffer = StringBuffer();
      buffer.writeln('🧾 *Order Summary*');
      if (mealType != null) buffer.writeln('🍽️ Meal Type: $mealType');
      buffer.writeln('Meals: ${selectedMeals.join(', ')}');
      buffer.writeln('Plan: $plan');
      if (plan == 'Weekly' &&
          selectedDates != null &&
          selectedDates!.isNotEmpty) {
        buffer.writeln('Delivery Days: ${selectedDates!.length}');
        buffer.writeln(
          selectedDates!
              .map((d) => DateFormat('EEE, MMM d').format(d))
              .join(', '),
        );
      } else {
        buffer.writeln(
          'Start: ${DateFormat('EEE, MMM d, y').format(startDate)}',
        );
        if (plan != 'Daily') {
          buffer.writeln('End: ${DateFormat('EEE, MMM d, y').format(endDate)}');
          buffer.writeln('Duration: $daysCount days');
        }
      }
      buffer.writeln('Price per meal: ₹$basePricePerMeal');
      buffer.writeln(
        'Total Meals × Days: ${selectedMeals.length} × $daysCount',
      );
      buffer.writeln('💰 Total Amount: ₹${totalPrice.toStringAsFixed(2)}');
      return buffer.toString();
    } catch (e) {
      debugPrint('Error building share text: $e');
      return 'Order Summary details unavailable.';
    }
  }

  void shareOrderDetails(BuildContext context) {
    final text = buildShareText();
    try {
      Share.share(text, subject: 'Order Summary');
    } catch (e) {
      debugPrint('Share failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to share order details')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        try {
          final isSmallScreen = constraints.maxWidth < 360;
          final titleFontSize = isSmallScreen ? 16.0 : 18.0;
          final labelFontSize = isSmallScreen ? 12.0 : 14.0;
          final valueFontSize = isSmallScreen ? 13.0 : 14.0;
          final totalFontSize = isSmallScreen ? 14.0 : 16.0;
          final contentPadding = isSmallScreen ? 12.0 : 16.0;

          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: EdgeInsets.all(contentPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Order Summary',
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Share',
                        icon: const Icon(Icons.share, color: Colors.green),
                        onPressed: () => shareOrderDetails(context),
                      ),
                    ],
                  ),
                  const Divider(height: 20, thickness: 1),

                  if (mealType != null) ...[
                    _buildSummaryRow(
                      'Bike Type',
                      mealType!,
                      labelFontSize,
                      valueFontSize,
                    ),
                    const SizedBox(height: 8),
                  ],

                  _buildSummaryRow(
                    'Spares(s)',
                    selectedMeals.join(', '),
                    labelFontSize,
                    valueFontSize,
                    secondaryText: '₹$basePricePerMeal per meal',
                  ),
                  const SizedBox(height: 8),

                  _buildSummaryRow('Plan', plan, labelFontSize, valueFontSize),
                  const SizedBox(height: 8),

                  if (plan == 'Weekly' &&
                      selectedDates != null &&
                      selectedDates!.isNotEmpty) ...[
                    _buildSummaryRow(
                      'Delivery Days',
                      '${selectedDates!.length} days',
                      labelFontSize,
                      valueFontSize,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 8),
                      child: Text(
                        selectedDates!
                            .map((d) => DateFormat('EEE, MMM d').format(d))
                            .join('\n'),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: labelFontSize - 2,
                        ),
                      ),
                    ),
                  ] else ...[
                    _buildSummaryRow(
                      'Start Date',
                      DateFormat('EEE, MMM d, y').format(startDate),
                      labelFontSize,
                      valueFontSize,
                    ),
                    if (plan != 'Daily') ...[
                      const SizedBox(height: 4),
                      _buildSummaryRow(
                        'End Date',
                        DateFormat('EEE, MMM d, y').format(endDate),
                        labelFontSize,
                        valueFontSize,
                      ),
                      _buildSummaryRow(
                        'Duration',
                        '$daysCount days',
                        labelFontSize,
                        valueFontSize,
                      ),
                    ],
                  ],

                  const Divider(height: 20, thickness: 1),

                  _buildSummaryRow(
                    'Price Calculation',
                    '${selectedMeals.length} meal(s) × $daysCount day(s)',
                    labelFontSize,
                    valueFontSize,
                    secondaryText:
                        '₹${selectedMeals.length * daysCount * basePricePerMeal}',
                  ),

                  const Divider(height: 20, thickness: 1),

                  _buildSummaryRow(
                    'Total Amount',
                    '₹${totalPrice.toStringAsFixed(2)}',
                    labelFontSize,
                    totalFontSize,
                    isBold: true,
                    isTotal: true,
                  ),
                ],
              ),
            ),
          );
        } catch (e) {
          debugPrint('Error building widget: $e');
          return const Center(child: Text('Could not load order summary'));
        }
      },
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    double labelFontSize,
    double valueFontSize, {
    String? secondaryText,
    bool isBold = false,
    bool isTotal = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  color: isTotal ? Colors.deepOrange : Colors.grey[700],
                  fontSize: labelFontSize,
                ),
              ),
            ),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  color: isTotal ? Colors.deepOrange : Colors.black,
                  fontSize: valueFontSize,
                ),
              ),
            ),
          ],
        ),
        if (secondaryText != null)
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 2),
            child: Text(
              secondaryText,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: labelFontSize - 2,
              ),
            ),
          ),
      ],
    );
  }
}
