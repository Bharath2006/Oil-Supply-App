import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'date_selection_widget.dart';
import 'order_model.dart';
import 'order_repository.dart';
import 'order_summary_widget.dart';
import 'order_view_model.dart';
import 'payment_widgets.dart';

class OrderScreen extends StatefulWidget {
  final String? selectedMeal;
  final int? mealPrice;
  final String? mealType;

  const OrderScreen({
    super.key,
    this.selectedMeal,
    this.mealPrice,
    this.mealType,
  });

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _viewModel = OrderViewModel(repository: OrderRepository());

  String _selectedPlan = 'Daily';
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  List<DateTime> _selectedDates = [];
  String _selectedAddress = 'Coimbatore';
  final List<String> _selectedMeals = [];
  String _selectedMealType = 'Lunch';

  final List<String> _addresses = [
    'Karumathampatti',
    'Coimbatore',
    'Tirupur',
    'Sulur',
    'Other',
  ];
  final List<String> _planOptions = ['Daily', 'Weekly', 'Monthly'];

  @override
  void initState() {
    super.initState();
    if (widget.selectedMeal != null && widget.selectedMeal!.isNotEmpty) {
      _selectedMeals.add(widget.selectedMeal!);
    }
    if (widget.mealType != null) {
      _selectedMealType = widget.mealType!;
    }
    _selectedDates.add(_startDate);

    _viewModel.addListener(() {
      if (_viewModel.error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_viewModel.error!)));
        _viewModel.clearError();
      }
      if (_viewModel.order != null) {
        _showSuccessDialog(_viewModel.order!.token);
      }
    });
  }

  int get _basePricePerMeal => widget.mealPrice ?? 90;
  int get _daysCount => _selectedPlan == 'Weekly'
      ? _selectedDates.length
      : (_selectedPlan == 'Monthly' ? 30 : 1);

  DateTime get _endDate {
    if (_selectedPlan == 'Weekly' && _selectedDates.isNotEmpty) {
      return _selectedDates.last;
    }
    return _startDate.add(Duration(days: _daysCount - 1));
  }

  int get _totalPrice => _selectedMeals.length * _basePricePerMeal * _daysCount;

  String _generateToken() {
    final random = DateTime.now().millisecondsSinceEpoch % 10000;
    return 'TFN${random.toString().padLeft(4, '0')}';
  }

  void _showPaymentConfirmation() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields correctly'),
        ),
      );
      return;
    }
    if (_selectedMeals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one meal')),
      );
      return;
    }
    if (_selectedPlan == 'Weekly' && _selectedDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one date for weekly plan'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => PaymentOptionsDialog(
        onQRSelected: () {
          Navigator.pop(context);
          _showQRPayment();
        },
        onUPISelected: () {
          Navigator.pop(context);
          _showUPIPayment();
        },
      ),
    );
  }

  void _showQRPayment() {
    showDialog(
      context: context,
      builder: (context) => QRPaymentDialog(
        totalPrice: _totalPrice.toDouble(),
        onPaymentComplete: () => _showTransactionDetailsForm(),
      ),
    );
  }

  void _showUPIPayment() {
    showDialog(
      context: context,
      builder: (context) => UPIPaymentDialog(
        totalPrice: _totalPrice.toDouble(),
        onPaymentComplete: () => _showTransactionDetailsForm(),
      ),
    );
  }

  void _showTransactionDetailsForm() {
    showDialog(
      context: context,
      builder: (context) => TransactionDetailsForm(
        onSubmit: (upiId, upiName, txnId) {
          _submitOrder(upiId, upiName, txnId);
          Navigator.pop(context);
        },
        error: _viewModel.error,
      ),
    );
  }

  List<DateTime> _generateDateRange(DateTime start, DateTime end) {
    List<DateTime> dates = [];
    DateTime current = start;
    while (!current.isAfter(end)) {
      dates.add(current);
      current = current.add(const Duration(days: 1));
    }
    return dates;
  }

  Future<void> _submitOrder(String upiId, String upiName, String txnId) async {
    final token = _generateToken();
    final deliveryStatus = _generateDeliveryStatus();

    List<DateTime>? dates;

    if (_selectedPlan == 'Weekly') {
      dates = _selectedDates;
    } else if (_selectedPlan == 'Daily') {
      dates = [_startDate];
    } else if (_selectedPlan == 'Monthly') {
      dates = _generateDateRange(_startDate, _endDate);
    }

    final order = FoodOrder(
      userEmail:
          FirebaseAuth.instance.currentUser?.email ?? 'unknown@email.com',
      plan: _selectedPlan,
      startDate: _startDate,
      endDate: _endDate,
      selectedDates: dates,
      meals: _selectedMeals,
      mealType: _selectedMealType,
      mealPrice: _basePricePerMeal,
      address: _selectedAddress,
      upiId: upiId,
      upiName: upiName,
      txnId: txnId,
      totalPrice: _totalPrice.toDouble(),
      token: token,
      createdAt: DateTime.now(),
      deliveryStatus: deliveryStatus,
    );

    await _viewModel.submitOrder(order);
  }

  Map<String, Map<String, bool>> _generateDeliveryStatus() {
    final status = <String, Map<String, bool>>{};
    final days = _daysCount;

    for (int i = 0; i < days; i++) {
      final date = _startDate.add(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      status[dateStr] = {};
      for (final meal in _selectedMeals) {
        status[dateStr]![meal] = false;
      }
    }

    return status;
  }

  void _showSuccessDialog(String token) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('✅ Order Confirmed!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 60,
            ),
            const SizedBox(height: 16),
            const Text('Your order has been placed successfully'),
            Text(
              'Order ID: $token',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('Confirmation sent to your email.'),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Back to Home'),
            onPressed: () =>
                Navigator.popUntil(context, (route) => route.isFirst),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🍽️ Place Your Meal Order'),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(Icons.fastfood, 'Select Plan'),
                  _buildDropdown(_planOptions, _selectedPlan, (value) {
                    setState(() {
                      _selectedPlan = value!;
                      if (_selectedPlan != 'Weekly') {
                        _selectedDates = [_startDate];
                      }
                    });
                  }),

                  const SizedBox(height: 16),

                  DateSelectionWidget(
                    plan: _selectedPlan,
                    startDate: _startDate,
                    selectedDates: _selectedDates,
                    onDateSelected: (date) => setState(() => _startDate = date),
                    onWeeklyDatesSelected: (dates) => setState(() {
                      _selectedDates = dates..sort();
                      _startDate = dates.first;
                    }),
                    onMonthlyDatesSelected: (dates) => setState(() {
                      _selectedDates = dates..sort();
                      _startDate = dates.first;
                    }),
                  ),

                  const SizedBox(height: 16),

                  OrderSummaryWidget(
                    selectedMeals: _selectedMeals,
                    mealType: _selectedMealType,
                    plan: _selectedPlan,
                    startDate: _startDate,
                    endDate: _endDate,
                    selectedDates: _selectedPlan == 'Weekly'
                        ? _selectedDates
                        : null,
                    basePricePerMeal: _basePricePerMeal,
                    totalPrice: _totalPrice.toDouble(),
                  ),

                  const SizedBox(height: 16),

                  _buildSectionTitle(Icons.location_on, 'Delivery Address'),
                  _buildDropdown(_addresses, _selectedAddress, (value) {
                    setState(() => _selectedAddress = value!);
                  }),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _viewModel.isLoading
                          ? null
                          : _showPaymentConfirmation,
                      icon: const Icon(Icons.payment),
                      label: _viewModel.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Proceed to Payment',
                              style: TextStyle(fontSize: 16),
                            ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: Colors.green),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    List<String> items,
    String currentValue,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: currentValue,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
      validator: (value) =>
          (value == null || value.isEmpty) ? 'Required' : null,
    );
  }
}
