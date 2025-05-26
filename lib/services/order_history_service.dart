// services/order_history_service.dart (Proper SharedPreferences Version)
import 'dart:convert';
import 'package:onebanc_aayushm/models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderHistoryService {
  static const String _orderHistoryKey = 'order_history';

  // Save order to history
  static Future<void> saveOrder(OrderHistory order) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> existingOrders = prefs.getStringList(_orderHistoryKey) ?? [];
      
      // Add new order at the beginning (most recent first)
      existingOrders.insert(0, jsonEncode(order.toJson()));
      
      // Keep only last 50 orders to avoid too much storage
      if (existingOrders.length > 50) {
        existingOrders = existingOrders.take(50).toList();
      }
      
      await prefs.setStringList(_orderHistoryKey, existingOrders);
      print('Order saved successfully: ${order.orderId}');
    } catch (e) {
      print('Error saving order to history: $e');
    }
  }

  // Get all orders from history
  static Future<List<OrderHistory>> getOrderHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> orderStrings = prefs.getStringList(_orderHistoryKey) ?? [];
      
      List<OrderHistory> orders = orderStrings.map((orderString) {
        Map<String, dynamic> json = jsonDecode(orderString);
        return OrderHistory.fromJson(json);
      }).toList();
      
      print('Retrieved ${orders.length} orders from history');
      return orders;
    } catch (e) {
      print('Error getting order history: $e');
      return [];
    }
  }

  // Clear order history
  static Future<void> clearOrderHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_orderHistoryKey);
      print('Order history cleared');
    } catch (e) {
      print('Error clearing order history: $e');
    }
  }

  // Get order count
  static Future<int> getOrderCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> orderStrings = prefs.getStringList(_orderHistoryKey) ?? [];
      return orderStrings.length;
    } catch (e) {
      print('Error getting order count: $e');
      return 0;
    }
  }
}