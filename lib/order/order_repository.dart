import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'order_model.dart';

class OrderRepository {
  final FirebaseFirestore _firestore;

  OrderRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<FoodOrder> createOrder(FoodOrder order) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw OrderException('User not authenticated');
      }

      final uid = currentUser.uid;
      final orderMap = order.toMap();

      final globalOrderRef = _firestore.collection('orders').doc(order.token);
      await globalOrderRef.set(orderMap);

      final userOrderRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('orders')
          .doc(order.token);
      await userOrderRef.set(orderMap);

      return order.copyWith(id: globalOrderRef.id);
    } catch (e) {
      throw OrderException('Failed to create order: ${e.toString()}');
    }
  }

  Future<String> generateCSV(FoodOrder order) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/order_${order.token}.csv');

      final csvData = [
        ['Order Summary'],
        ['Token', order.token],
        ['Date', DateFormat('yyyy-MM-dd HH:mm').format(order.createdAt)],
        ['Plan', order.plan],
        ['Start Date', DateFormat('yyyy-MM-dd').format(order.startDate)],
        ['End Date', DateFormat('yyyy-MM-dd').format(order.endDate)],
        ['Meals', order.meals.join(', ')],
        ['Meal Price', '₹${order.mealPrice}'],
        ['Total Price', '₹${order.totalPrice}'],
        ['Delivery Address', order.address],
        ['Transaction ID', order.txnId],
      ];

      final csvString = const ListToCsvConverter().convert(csvData);
      await file.writeAsString(csvString);
      return file.path;
    } catch (e) {
      throw OrderException('Failed to generate CSV: ${e.toString()}');
    }
  }
}

class OrderException implements Exception {
  final String message;
  OrderException(this.message);

  @override
  String toString() => 'OrderException: $message';
}
