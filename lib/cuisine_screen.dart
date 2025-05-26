import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:onebanc_aayushm/animated_button.dart';
import 'package:onebanc_aayushm/app_state_mgmt.dart';
import 'package:onebanc_aayushm/cart_screen.dart';
import 'package:onebanc_aayushm/data_service.dart';
import 'package:onebanc_aayushm/models/models.dart';

class CuisineScreen extends StatefulWidget {
  final Cuisine cuisine;

  const CuisineScreen({super.key, required this.cuisine});

  @override
  State<CuisineScreen> createState() => _CuisineScreenState();
}

class _CuisineScreenState extends State<CuisineScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  final AppState _appState = AppState();
  
  // Data state variables
  List<Dish> _dishes = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _appState.addListener(_updateState);
    _loadDishes();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _appState.removeListener(_updateState);
    super.dispose();
  }

  void _updateState() {
    if (mounted) setState(() {});
  }

  Future<void> _loadDishes() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final dishes = await DataService.getDishesByCuisine(widget.cuisine.id);
      
      setState(() {
        _dishes = dishes;
        _isLoading = false;
      });

      // Start animation after data is loaded
      _slideController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load dishes. Please try again.';
      });
    }
  }

  Future<void> _refreshDishes() async {
    try {
      await DataService.refreshData();
      await _loadDishes();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_appState.isHindi 
                ? 'डेटा रिफ्रेश करने में त्रुटि' 
                : 'Error refreshing data'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshDishes,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            _isLoading
                ? _buildLoadingContent()
                : _errorMessage != null
                    ? _buildErrorContent()
                    : _buildDishesContent(),
          ],
        ),
      ),
      floatingActionButton: _appState.totalItemsInCart > 0
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartScreen()),
              ),
              backgroundColor: const Color(0xFF00B894),
              icon: const Icon(Icons.shopping_cart),
              label: Text('${_appState.totalItemsInCart}'),
            )
          : null,
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: const Color(0xFF6C5CE7),
      leading: AnimatedButton(
        onPressed: () => Navigator.pop(context),
        backgroundColor: Colors.white.withOpacity(0.2),
        padding: const EdgeInsets.all(8),
        child: const Icon(Icons.arrow_back, color: Colors.white),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF6C5CE7),
                const Color(0xFF6C5CE7).withOpacity(0.8),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.restaurant_menu,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _appState.isHindi ? widget.cuisine.nameHindi : widget.cuisine.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                _isLoading
                    ? (_appState.isHindi ? 'लोड हो रहा है...' : 'Loading...')
                    : _appState.isHindi 
                        ? '${_dishes.length} व्यंजन उपलब्ध'
                        : '${_dishes.length} dishes available',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingContent() {
    return const SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C5CE7)),
            ),
            SizedBox(height: 16),
            Text(
              'Loading dishes...',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF636E72),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorContent() {
    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Color(0xFFE17055),
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF636E72),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              AnimatedButton(
                onPressed: _loadDishes,
                backgroundColor: const Color(0xFF6C5CE7),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Text(
                  _appState.isHindi ? 'पुनः प्रयास करें' : 'Retry',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDishesContent() {
    if (_dishes.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.restaurant,
                size: 64,
                color: Color(0xFF636E72),
              ),
              const SizedBox(height: 16),
              Text(
                _appState.isHindi 
                    ? 'इस श्रेणी में कोई व्यंजन उपलब्ध नहीं है'
                    : 'No dishes available in this category',
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF636E72),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              AnimatedButton(
                onPressed: _loadDishes,
                backgroundColor: const Color(0xFF6C5CE7),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Text(
                  _appState.isHindi ? 'रिफ्रेश करें' : 'Refresh',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SlideTransition(
        position: _slideAnimation,
        child: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 1,
            childAspectRatio: 2.5,
            mainAxisSpacing: 16,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 400 + (index * 100)),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: Opacity(
                      opacity: value,
                      child: _buildDishListItem(_dishes[index]),
                    ),
                  );
                },
              );
            },
            childCount: _dishes.length,
          ),
        ),
      ),
    );
  }

  Widget _buildDishListItem(Dish dish) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 120,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.orange.withOpacity(0.8),
                  Colors.deepOrange.withOpacity(0.6),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.fastfood,
                size: 40,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _appState.isHindi ? dish.nameHindi : dish.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3436),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '₹${dish.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE17055),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${dish.rating}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF636E72),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: AnimatedButton(
              onPressed: () {
                _appState.addToCart(dish);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _appState.isHindi 
                          ? '${dish.nameHindi} कार्ट में जोड़ा गया'
                          : '${dish.name} added to cart',
                    ),
                    backgroundColor: const Color(0xFF00B894),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              backgroundColor: const Color(0xFF00B894),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(
                _appState.isHindi ? 'जोड़ें' : 'Add',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}