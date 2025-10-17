import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class FoodOrder {
  final String? id;
  final String userEmail;
  final String plan;
  final DateTime startDate;
  final DateTime endDate;
  final List<DateTime>? selectedDates;
  final List<String> meals;
  final String mealType;
  final int mealPrice;
  final String address;
  final String upiId;
  final String upiName;
  final String txnId;
  final double totalPrice;
  final bool confirmed;
  final bool csvDownloaded;
  final String token;
  final DateTime createdAt;
  final Map<String, Map<String, bool>> deliveryStatus;

  FoodOrder({
    this.id,
    required this.userEmail,
    required this.plan,
    required this.startDate,
    required this.endDate,
    this.selectedDates,
    required this.meals,
    required this.mealType,
    required this.mealPrice,
    required this.address,
    required this.upiId,
    required this.upiName,
    required this.txnId,
    required this.totalPrice,
    this.confirmed = true,
    this.csvDownloaded = false,
    required this.token,
    required this.createdAt,
    required this.deliveryStatus,
  });

  factory FoodOrder.fromMap(Map<String, dynamic> map) {
    return FoodOrder(
      id: map['id'],
      userEmail: map['email'] ?? '',
      plan: map['plan'] ?? '',
      startDate: DateFormat('yyyy-MM-dd').parse(map['start_date']),
      endDate: DateFormat('yyyy-MM-dd').parse(map['end_date']),
      selectedDates: map['selected_dates'] != null
          ? (map['selected_dates'] as List)
                .map((d) => DateFormat('yyyy-MM-dd').parse(d))
                .toList()
          : null,
      meals: List<String>.from(map['meals'] ?? []),
      mealType: map['mealtype'] ?? 'Lunch',
      mealPrice: map['meal_price'] ?? 0,
      address: map['address'] ?? '',
      upiId: map['upi_id'] ?? '',
      upiName: map['upi_name'] ?? '',
      txnId: map['txn_id'] ?? '',
      totalPrice: (map['price'] is int)
          ? (map['price'] as int).toDouble()
          : (map['price'] ?? 0).toDouble(),
      confirmed: map['confirmed'] ?? true,
      csvDownloaded: map['csv_downloaded'] ?? false,
      token: map['token'] ?? '',
      createdAt: map['created_at'] is Timestamp
          ? (map['created_at'] as Timestamp).toDate()
          : DateTime.now(),
      deliveryStatus: _parseDeliveryStatus(map['delivery_status']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'email': userEmail,
      'plan': plan,
      'start_date': DateFormat('yyyy-MM-dd').format(startDate),
      'end_date': DateFormat('yyyy-MM-dd').format(endDate),
      'selected_dates': selectedDates
          ?.map((d) => DateFormat('yyyy-MM-dd').format(d))
          .toList(),
      'meals': meals,
      'mealtype': mealType,
      'meal_price': mealPrice,
      'address': address,
      'upi_id': upiId,
      'upi_name': upiName,
      'txn_id': txnId,
      'price': totalPrice,
      'confirmed': confirmed,
      'csv_downloaded': csvDownloaded,
      'token': token,
      'created_at': FieldValue.serverTimestamp(),
      'delivery_status': deliveryStatus.map(
        (dateKey, mealMap) => MapEntry(
          dateKey,
          mealMap.map((meal, delivered) => MapEntry(meal, delivered)),
        ),
      ),
    };
  }

  static Map<String, Map<String, bool>> _parseDeliveryStatus(dynamic status) {
    final result = <String, Map<String, bool>>{};
    if (status is Map) {
      status.forEach((dateKey, mealMap) {
        if (mealMap is Map) {
          result[dateKey] = {};
          mealMap.forEach((meal, delivered) {
            if (delivered is bool) {
              result[dateKey]![meal] = delivered;
            }
          });
        }
      });
    }
    return result;
  }

  FoodOrder copyWith({
    String? id,
    String? userEmail,
    String? plan,
    DateTime? startDate,
    DateTime? endDate,
    List<DateTime>? selectedDates,
    List<String>? meals,
    String? mealType,
    int? mealPrice,
    String? address,
    String? upiId,
    String? upiName,
    String? txnId,
    double? totalPrice,
    bool? confirmed,
    bool? csvDownloaded,
    String? token,
    DateTime? createdAt,
    Map<String, Map<String, bool>>? deliveryStatus,
  }) {
    return FoodOrder(
      id: id ?? this.id,
      userEmail: userEmail ?? this.userEmail,
      plan: plan ?? this.plan,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      selectedDates: selectedDates ?? this.selectedDates,
      meals: meals ?? this.meals,
      mealType: mealType ?? this.mealType,
      mealPrice: mealPrice ?? this.mealPrice,
      address: address ?? this.address,
      upiId: upiId ?? this.upiId,
      upiName: upiName ?? this.upiName,
      txnId: txnId ?? this.txnId,
      totalPrice: totalPrice ?? this.totalPrice,
      confirmed: confirmed ?? this.confirmed,
      csvDownloaded: csvDownloaded ?? this.csvDownloaded,
      token: token ?? this.token,
      createdAt: createdAt ?? this.createdAt,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
    );
  }
}
