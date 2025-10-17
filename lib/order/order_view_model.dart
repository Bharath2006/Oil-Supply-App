import 'package:flutter/material.dart';
import 'order_model.dart';
import 'order_repository.dart';

class OrderViewModel with ChangeNotifier {
  final OrderRepository _repository;
  OrderViewModel({required OrderRepository repository})
    : _repository = repository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  FoodOrder? _order;
  FoodOrder? get order => _order;

  Future<void> submitOrder(FoodOrder order) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _order = (await _repository.createOrder(order)) as FoodOrder?;

      await _repository.generateCSV(order);
    } on OrderException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'An unexpected error occurred: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
