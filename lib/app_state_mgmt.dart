import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:onebanc_aayushm/data_service.dart';
import 'package:onebanc_aayushm/models/models.dart';


class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  bool _isHindi = false;
  final List<CartItem> _cartItems = [];
  final List<Function> _listeners = [];

  bool get isHindi => _isHindi;
  List<CartItem> get cartItems => List.unmodifiable(_cartItems);
  int get totalItemsInCart => _cartItems.fold(0, (sum, item) => sum + item.quantity);
  double get totalAmount => _cartItems.fold(0.0, (sum, item) => sum + (item.dish.price * item.quantity));
  double get cgst => totalAmount * 0.025;
  double get sgst => totalAmount * 0.025;
  double get grandTotal => totalAmount + cgst + sgst;

  void toggleLanguage() {
    _isHindi = !_isHindi;
    _notifyListeners();
    notifyListeners(); // For ChangeNotifier
  }

  void addToCart(Dish dish) {
    final existingIndex = _cartItems.indexWhere((item) => item.dish.id == dish.id);
    if (existingIndex != -1) {
      _cartItems[existingIndex].quantity++;
    } else {
      _cartItems.add(CartItem(dish: dish));
    }
    _notifyListeners();
    notifyListeners(); // For ChangeNotifier
  }

  // New method to remove one item from cart
  void removeFromCart(Dish dish) {
    final existingItemIndex = _cartItems.indexWhere((item) => item.dish.id == dish.id);
    
    if (existingItemIndex >= 0) {
      if (_cartItems[existingItemIndex].quantity > 1) {
        _cartItems[existingItemIndex].quantity--;
      } else {
        _cartItems.removeAt(existingItemIndex);
      }
      _notifyListeners();
      notifyListeners(); // For ChangeNotifier
    }
  }

  // New method to get the count of a specific item in cart
  int getItemCount(String dishId) {
    final cartItem = _cartItems.firstWhere(
      (item) => item.dish.id == dishId,
      orElse: () => CartItem(
        dish: Dish(
          id: '', 
          name: '', 
          nameHindi: '',
          image: '', 
          price: 0, 
          rating: 0, 
          cuisineId: '',
          isFavorite: false
        ), 
        quantity: 0
      ),
    );
    return cartItem.quantity;
  }

  void updateCartItemQuantity(String dishId, int quantity) {
    final index = _cartItems.indexWhere((item) => item.dish.id == dishId);
    if (index != -1) {
      if (quantity <= 0) {
        _cartItems.removeAt(index);
      } else {
        _cartItems[index].quantity = quantity;
      }
      _notifyListeners();
      notifyListeners(); // For ChangeNotifier
    }
  }

  void clearCart() {
    _cartItems.clear();
    _notifyListeners();
    notifyListeners(); // For ChangeNotifier
  }

  void addListener(Function listener) {
    _listeners.add(listener);
  }

  void removeListener(Function listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (var listener in _listeners) {
      listener();
    }
  }

  // Payment functionality
  Future<PaymentResponse> processPayment() async {
    if (_cartItems.isEmpty) {
      throw Exception('Cart is empty');
    }

    try {
      final response = await DataService.makePayment(
        totalAmount: grandTotal,
        totalItems: totalItemsInCart,
        cartItems: _cartItems,
      );
      
      if (response.responseCode == 200) {
        clearCart(); // Clear cart after successful payment
      }
      
      return response;
    } catch (e) {
      throw Exception('Payment failed: $e');
    }
  }
}