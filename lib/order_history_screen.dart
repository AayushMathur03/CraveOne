// screens/order_history_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:onebanc_aayushm/animated_button.dart';
import 'package:onebanc_aayushm/app_state_mgmt.dart';
import 'package:onebanc_aayushm/models/models.dart';
import 'package:onebanc_aayushm/services/order_history_service.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final AppState _appState = AppState();
  List<OrderHistory> _orderHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    
    _loadOrderHistory();
    _appState.addListener(_updateState);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _appState.removeListener(_updateState);
    super.dispose();
  }

  void _updateState() {
    if (mounted) setState(() {});
  }

  Future<void> _loadOrderHistory() async {
    try {
      final orders = await OrderHistoryService.getOrderHistory();
      setState(() {
        _orderHistory = orders;
        _isLoading = false;
      });
      _fadeController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _fadeController.forward();
    }
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
                  _appState.isHindi ? 'ऑर्डर इतिहास' : 'Order History',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              actions: [
                if (_orderHistory.isNotEmpty)
                  AnimatedButton(
                    onPressed: _showClearHistoryDialog,
                    backgroundColor: Colors.white.withOpacity(0),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.delete_sweep, color: Colors.white),
                  ),
                const SizedBox(width: 16),
              ],
            ),
            _isLoading
                ? const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _orderHistory.isEmpty
                    ? SliverFillRemaining(
                        child: _buildEmptyHistory(),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return TweenAnimationBuilder<double>(
                              duration: Duration(milliseconds: 200 + (index * 100)),
                              tween: Tween(begin: 0.0, end: 1.0),
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(30 * (1 - value), 0),
                                  child: Opacity(
                                    opacity: value,
                                    child: _buildOrderCard(_orderHistory[index]),
                                  ),
                                );
                              },
                            );
                          },
                          childCount: _orderHistory.length,
                        ),
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyHistory() {
    return Center(
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
              Icons.history,
              size: 60,
              color: Colors.grey.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _appState.isHindi ? 'कोई ऑर्डर इतिहास नहीं' : 'No Order History',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _appState.isHindi 
                ? 'आपने अभी तक कोई ऑर्डर नहीं दिया है'
                : 'You haven\'t placed any orders yet',
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
              _appState.isHindi ? 'ऑर्डर करें' : 'Start Ordering',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderHistory order) {
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF74B9FF), Color(0xFF0984E3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _appState.isHindi ? 'ऑर्डर #${order.orderId}' : 'Order #${order.orderId}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFormat.format(order.orderDate),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '₹${order.grandTotal.toStringAsFixed(2)}',
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
          
          // Order Items
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _appState.isHindi 
                      ? '${order.totalItems} आइटम्स'
                      : '${order.totalItems} Items',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3436),
                  ),
                ),
                const SizedBox(height: 12),
                ...order.items.take(3).map((item) => _buildOrderItem(item)),
                if (order.items.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _appState.isHindi 
                          ? 'और ${order.items.length - 3} आइटम्स...'
                          : 'and ${order.items.length - 3} more items...',
                      style: const TextStyle(
                        color: Color(0xFF636E72),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                
                // Transaction Info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _appState.isHindi ? 'लेनदेन ID:' : 'Transaction ID:',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF636E72),
                      ),
                    ),
                    Text(
                      order.transactionRefNo,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3436),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(OrderItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: item.dishImage.isNotEmpty
                  ? Image.network(
                      item.dishImage,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.orange.withOpacity(0.8),
                                Colors.deepOrange.withOpacity(0.6),
                              ],
                            ),
                          ),
                          child: const Icon(
                            Icons.fastfood,
                            color: Colors.white,
                            size: 20,
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
                      ),
                      child: const Icon(
                        Icons.fastfood,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _appState.isHindi ? item.dishNameHindi : item.dishName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3436),
                  ),
                ),
                Text(
                  '₹${item.price.toStringAsFixed(0)} × ${item.quantity}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF636E72),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            _appState.isHindi ? 'इतिहास साफ़ करें?' : 'Clear History?',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            _appState.isHindi 
                ? 'क्या आप सभी ऑर्डर इतिहास को हटाना चाहते हैं?'
                : 'Are you sure you want to remove all order history?',
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
              onPressed: () async {
                await OrderHistoryService.clearOrderHistory();
                Navigator.pop(context);
                _loadOrderHistory();
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
}