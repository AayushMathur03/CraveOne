import 'package:flutter/material.dart';
import 'package:onebanc_aayushm/animated_button.dart';
import 'package:onebanc_aayushm/app_state_mgmt.dart';
import 'package:onebanc_aayushm/models/models.dart';
import 'package:onebanc_aayushm/order_history_screen.dart';
import 'package:onebanc_aayushm/services/api_service.dart';
import 'package:onebanc_aayushm/services/order_history_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _bounceController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _bounceAnimation;
  final AppState _appState = AppState();
  bool _isProcessingPayment = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    
    _bounceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );
    
    _fadeController.forward();
    _bounceController.forward();
    _appState.addListener(_updateState);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _bounceController.dispose();
    _appState.removeListener(_updateState);
    super.dispose();
  }

  void _updateState() {
    if (mounted) setState(() {});
  }

  Future<void> _saveOrderToHistory(String txnRefNo, String responseMessage) async {
    try {
      // Generate unique order ID
      String orderId = 'ORD${DateTime.now().millisecondsSinceEpoch}';
      
      // Convert cart items to order items
      List<OrderItem> orderItems = _appState.cartItems.map((cartItem) {
        return OrderItem(
          dishId: cartItem.dish.id,
          dishName: cartItem.dish.name,
          dishNameHindi: cartItem.dish.nameHindi,
          dishImage: cartItem.dish.image,
          price: cartItem.dish.price,
          quantity: cartItem.quantity,
          cuisineId: cartItem.dish.cuisineId,
        );
      }).toList();

      // Calculate total items
      int totalItems = _appState.cartItems.fold(
        0, 
        (sum, item) => sum + item.quantity,
      );

      // Create order history object
      OrderHistory orderHistory = OrderHistory(
        orderId: orderId,
        transactionRefNo: txnRefNo,
        orderDate: DateTime.now(),
        items: orderItems,
        subtotal: _appState.totalAmount,
        cgst: _appState.cgst,
        sgst: _appState.sgst,
        grandTotal: _appState.grandTotal,
        totalItems: totalItems,
        status: 'completed',
      );

      // Save to history
      await OrderHistoryService.saveOrder(orderHistory);
    } catch (e) {
      print('Error saving order to history: $e');
    }
  }

  void _showPaymentSuccessDialog(String txnRefNo, String responseMessage) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: Color(0xFF00B894),
                size: 80,
              ),
              const SizedBox(height: 20),
              Text(
                _appState.isHindi ? 'भुगतान सफल!' : 'Payment Successful!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3436),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                responseMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF00B894),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _appState.isHindi 
                    ? 'आपका ऑर्डर प्राप्त हो गया है। धन्यवाद!'
                    : 'Your order has been received. Thank you!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF636E72),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6FA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      _appState.isHindi ? 'लेनदेन संदर्भ संख्या' : 'Transaction Reference',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF636E72),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      txnRefNo,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF2D3436),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AnimatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const OrderHistoryScreen(),
                          ),
                        );
                      },
                      backgroundColor: const Color(0xFF74B9FF),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Text(
                        _appState.isHindi ? 'इतिहास देखें' : 'View History',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AnimatedButton(
                      onPressed: () {
                        _appState.clearCart();
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                      backgroundColor: const Color(0xFF00B894),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Text(
                        _appState.isHindi ? 'होम पर जाएं' : 'Go to Home',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 120,
              pinned: true,
              backgroundColor: const Color(0xFF6C5CE7),
              leading: AnimatedButton(
                onPressed: () => Navigator.pop(context),
                backgroundColor: Colors.white.withOpacity(0),
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                title: Text(
                  _appState.isHindi ? 'आपका कार्ट' : 'Your Cart',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              actions: [
                if (_appState.cartItems.isNotEmpty)
                  AnimatedButton(
                    onPressed: _showClearCartDialog,
                    backgroundColor: Colors.white.withOpacity(0),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                const SizedBox(width: 16),
              ],
            ),
            _appState.cartItems.isEmpty
                ? SliverFillRemaining(
                    child: _buildEmptyCart(),
                  )
                : SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        _buildCartItems(),
                        const SizedBox(height: 20),
                        _buildBillSummary(),
                        const SizedBox(height: 20),
                        _buildPlaceOrderButton(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCart() {
    return ScaleTransition(
      scale: _bounceAnimation,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 60,
                color: Colors.grey.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _appState.isHindi ? 'आपका कार्ट खाली है' : 'Your cart is empty',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _appState.isHindi 
                  ? 'कुछ स्वादिष्ट व्यंजन जोड़ें!'
                  : 'Add some delicious dishes!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 32),
            AnimatedButton(
              onPressed: () => Navigator.pop(context),
              backgroundColor: const Color(0xFF74B9FF),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: Text(
                _appState.isHindi ? 'शॉपिंग शुरू करें' : 'Start Shopping',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItems() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            _appState.isHindi ? 'आइटम्स' : 'Items',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _appState.cartItems.length,
          itemBuilder: (context, index) {
            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 300 + (index * 100)),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(30 * (1 - value), 0),
                  child: Opacity(
                    opacity: value,
                    child: _buildCartItem(_appState.cartItems[index], index),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildCartItem(CartItem cartItem, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: cartItem.dish.image.isNotEmpty
                    ? Image.network(
                        cartItem.dish.image,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.orange.withOpacity(0.8),
                                  Colors.deepOrange.withOpacity(0.6),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.orange.withOpacity(0.8),
                                  Colors.deepOrange.withOpacity(0.6),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.fastfood,
                              color: Colors.white,
                              size: 30,
                            ),
                          );
                        },
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange.withOpacity(0.8),
                              Colors.deepOrange.withOpacity(0.6),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.fastfood,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _appState.isHindi 
                        ? cartItem.dish.nameHindi 
                        : cartItem.dish.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3436),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${cartItem.dish.price.toStringAsFixed(0)} × ${cartItem.quantity}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF636E72),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                AnimatedButton(
                  onPressed: () {
                    if (cartItem.quantity > 1) {
                      _appState.updateCartItemQuantity(
                        cartItem.dish.id,
                        cartItem.quantity - 1,
                      );
                    } else {
                      _appState.updateCartItemQuantity(cartItem.dish.id, 0);
                    }
                  },
                  backgroundColor: const Color(0xFFE17055),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(Icons.remove, color: Colors.white, size: 16),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '${cartItem.quantity}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3436),
                    ),
                  ),
                ),
                AnimatedButton(
                  onPressed: () {
                    _appState.updateCartItemQuantity(
                      cartItem.dish.id,
                      cartItem.quantity + 1,
                    );
                  },
                  backgroundColor: const Color(0xFF00B894),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(Icons.add, color: Colors.white, size: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillSummary() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF74B9FF), Color(0xFF0984E3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF74B9FF).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _appState.isHindi ? 'बिल का विवरण' : 'Bill Summary',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _buildBillRow(
            _appState.isHindi ? 'कुल राशि' : 'Subtotal',
            '₹${_appState.totalAmount.toStringAsFixed(2)}',
          ),
          _buildBillRow('CGST (2.5%)', '₹${_appState.cgst.toStringAsFixed(2)}'),
          _buildBillRow('SGST (2.5%)', '₹${_appState.sgst.toStringAsFixed(2)}'),
          const Divider(color: Colors.white, thickness: 1),
          _buildBillRow(
            _appState.isHindi ? 'कुल योग' : 'Grand Total',
            '₹${_appState.grandTotal.toStringAsFixed(2)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildBillRow(String label, String amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: Colors.white,
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceOrderButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ScaleTransition(
        scale: _bounceAnimation,
        child: AnimatedButton(
          onPressed: _isProcessingPayment ? () {} : _placeOrder,
          backgroundColor: _isProcessingPayment 
              ? Colors.grey 
              : const Color(0xFF00B894),
          child: _isProcessingPayment
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _appState.isHindi ? 'प्रोसेसिंग...' : 'Processing...',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.payment, color: Colors.white),
                    const SizedBox(width: 12),
                    Text(
                      _appState.isHindi ? 'भुगतान करें' : 'Pay Now',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  void _showClearCartDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            _appState.isHindi ? 'कार्ट साफ़ करें?' : 'Clear Cart?',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            _appState.isHindi 
                ? 'क्या आप सभी आइटम्स को कार्ट से हटाना चाहते हैं?'
                : 'Are you sure you want to remove all items from cart?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                _appState.isHindi ? 'रद्द करें' : 'Cancel',
                style: const TextStyle(color: Color(0xFF636E72)),
              ),
            ),
            AnimatedButton(
              onPressed: () {
                _appState.clearCart();
                Navigator.pop(context);
              },
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                _appState.isHindi ? 'साफ़ करें' : 'Clear',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // IMPROVED PLACE ORDER METHOD WITH BETTER DEBUGGING
  void _placeOrder() async {
    if (_isProcessingPayment) return;

    // Validate cart before proceeding
    if (_appState.cartItems.isEmpty) {
      _showPaymentErrorDialog(
        _appState.isHindi 
            ? 'कार्ट खाली है। कृपया पहले कुछ आइटम जोड़ें।'
            : 'Cart is empty. Please add some items first.'
      );
      return;
    }

    // Validate total amount
    if (_appState.grandTotal <= 0) {
      _showPaymentErrorDialog(
        _appState.isHindi 
            ? 'अमान्य राशि। कृपया पुनः प्रयास करें।'
            : 'Invalid amount. Please try again.'
      );
      return;
    }

    setState(() {
      _isProcessingPayment = true;
    });

    try {
      // Debug print to check data before API call
      print('=== PAYMENT DEBUG INFO ===');
      print('Grand Total: ${_appState.grandTotal}');
      print('Cart Items Count: ${_appState.cartItems.length}');
      
      // Prepare payment items with validation
      List<PaymentItem> paymentItems = [];
      for (var cartItem in _appState.cartItems) {
        // Validate each cart item
        if (cartItem.dish.id.isEmpty || 
            cartItem.dish.price <= 0 || 
            cartItem.quantity <= 0) {
          throw Exception('Invalid cart item: ${cartItem.dish.name}');
        }
        
        paymentItems.add(PaymentItem(
          cuisineId: cartItem.dish.cuisineId,
          itemId: cartItem.dish.id,
          itemPrice: cartItem.dish.price,
          itemQuantity: cartItem.quantity,
        ));
      }

      // Calculate total items
      int totalItems = _appState.cartItems.fold(
        0, 
        (sum, item) => sum + item.quantity,
      );

      print('Total Items: $totalItems');
      print('Payment Items: ${paymentItems.length}');
      print('========================');

      // Make payment API call with timeout
      PaymentResponse paymentResponse = await ApiService.makePayment(
        totalAmount: _appState.grandTotal,
        totalItems: totalItems,
        items: paymentItems,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Payment request timed out. Please check your internet connection.');
        },
      );

      print('Payment Response Code: ${paymentResponse.responseCode}');
      print('Payment Response Message: ${paymentResponse.responseMessage}');

      // Handle payment response
      if (paymentResponse.responseCode == 200) {
        // Save order to history before showing success dialog
        await _saveOrderToHistory(
          paymentResponse.txnRefNo, 
          paymentResponse.responseMessage
        );
        _showPaymentSuccessDialog(
          paymentResponse.txnRefNo, 
          paymentResponse.responseMessage
        );
      } else {
        // Handle specific error codes
        String errorMessage = paymentResponse.responseMessage;
        if (paymentResponse.responseCode == 400) {
          errorMessage = _appState.isHindi 
              ? 'अमान्य भुगतान डेटा। कृपया पुनः प्रयास करें।'
              : 'Invalid payment data. Please try again.';
        } else if (paymentResponse.responseCode == 500) {
          errorMessage = _appState.isHindi 
              ? 'सर्वर त्रुटि। कृपया बाद में पुनः प्रयास करें।'
              : 'Server error. Please try again later.';
        }
        _showPaymentErrorDialog(errorMessage);
      }
    } catch (e) {
      print('Payment Error: $e');
      
      // Handle specific error types
      String errorMessage;
      if (e.toString().contains('timeout')) {
        errorMessage = _appState.isHindi 
            ? 'भुगतान का समय समाप्त हो गया। कृपया अपना इंटरनेट कनेक्शन जांचें।'
            : 'Payment timed out. Please check your internet connection.';
      } else if (e.toString().contains('network') || e.toString().contains('connection')) {
        errorMessage = _appState.isHindi 
            ? 'नेटवर्क त्रुटि। कृपया अपना इंटरनेट कनेक्शन जांचें।'
            : 'Network error. Please check your internet connection.';
      } else if (e.toString().contains('Invalid cart item')) {
        errorMessage = _appState.isHindi 
            ? 'कार्ट में कुछ आइटम अमान्य हैं। कृपया कार्ट को साफ़ करके पुनः प्रयास करें।'
            : 'Some cart items are invalid. Please clear cart and try again.';
      } else {
        errorMessage = _appState.isHindi 
            ? 'भुगतान में त्रुटि: ${e.toString()}'
            : 'Payment error: ${e.toString()}';
      }
      
      _showPaymentErrorDialog(errorMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
        });
      }
    }
  }


  void _showPaymentErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                _appState.isHindi ? 'भुगतान असफल' : 'Payment Failed',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          content: Text(
            errorMessage,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF636E72),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                _appState.isHindi ? 'ठीक है' : 'OK',
                style: const TextStyle(color: Color(0xFF636E72)),
              ),
            ),
            AnimatedButton(
              onPressed: () {
                Navigator.pop(context);
                _placeOrder(); // Retry payment
              },
              backgroundColor: const Color(0xFF00B894),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                _appState.isHindi ? 'पुनः प्रयास करें' : 'Retry',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}