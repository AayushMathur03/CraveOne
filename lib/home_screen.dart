import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:onebanc_aayushm/animated_button.dart';
import 'package:onebanc_aayushm/app_state_mgmt.dart';
import 'package:onebanc_aayushm/cart_screen.dart';
import 'package:onebanc_aayushm/cuisine_details_screen.dart';
import 'package:onebanc_aayushm/cuisine_screen.dart';
import 'package:onebanc_aayushm/data_service.dart';
import 'package:onebanc_aayushm/models/models.dart';
import 'package:onebanc_aayushm/order_history_screen.dart';
import 'package:onebanc_aayushm/search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final PageController _cuisineController =
      PageController(viewportFraction: 0.9); // Increased from 0.85
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final AppState _appState = AppState();

  // Data state variables
  List<Cuisine> _cuisines = [];
  List<Dish> _topDishes = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Page indicator state
  double _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _appState.addListener(_updateState);
    _loadData();

    // Add listener for page changes
    _cuisineController.addListener(() {
      if (_cuisineController.page != null) {
        setState(() {
          _currentPage = _cuisineController.page!;
        });
      }
    });
  }

  @override
  void dispose() {
    _cuisineController.dispose();
    _fadeController.dispose();
    _appState.removeListener(_updateState);
    super.dispose();
  }

  void _updateState() {
    if (mounted) setState(() {});
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Load cuisines and top dishes concurrently
      final results = await Future.wait([
        DataService.getCuisines(),
        DataService.getTopDishes(),
      ]);

      setState(() {
        _cuisines = results[0] as List<Cuisine>;
        _topDishes = results[1] as List<Dish>;
        _isLoading = false;
      });

      // Start fade animation after data is loaded
      _fadeController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load data. Please try again.';
      });
    }
  }

  Future<void> _refreshData() async {
    try {
      await DataService.refreshData();
      await _loadData();
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
        onRefresh: _refreshData,
        child: _isLoading
            ? _buildLoadingScreen()
            : _errorMessage != null
                ? _buildErrorScreen()
                : _buildMainContent(),
      ),
      floatingActionButton:
          _appState.totalItemsInCart > 0 ? _buildFloatingCartButton() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildLoadingScreen() {
    return CustomScrollView(
      slivers: [
        _buildAppBar(),
        const SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
                ),
                SizedBox(height: 16),
                Text(
                  'Loading delicious food...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF636E72),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorScreen() {
    return CustomScrollView(
      slivers: [
        _buildAppBar(),
        SliverFillRemaining(
          child: Center(
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
                  onPressed: _loadData,
                  backgroundColor: const Color(0xFFFF6B35),
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
      ],
    );
  }

  Widget _buildMainContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                _buildCuisineSection(),
                const SizedBox(height: 32),
                _buildTopDishesSection(),
                // Add bottom padding to account for floating button
                const SizedBox(height: 100), // Space for floating button
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingCartButton() {
    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const CartScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return ScaleTransition(scale: animation, child: child);
            },
          ),
        );
      },
      backgroundColor: const Color(0xFF6C5CE7),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shopping_cart, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Text(
            _appState.isHindi
                ? 'कार्ट देखें (${_appState.totalItemsInCart})'
                : 'View Cart (${_appState.totalItemsInCart})',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Updated _buildAppBar method for your home screen
Widget _buildAppBar() {
  return SliverAppBar(
    expandedHeight: 130,
    floating: true,
    pinned: true,
    elevation: 4,
    backgroundColor: const Color(0xFFFF6B35),
    flexibleSpace: FlexibleSpaceBar(
      background: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.2), Colors.transparent],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
        ),
      ),
      title: FittedBox(
        alignment: Alignment.center,
        child: Text(
          _appState.isHindi ? '  क्रेववन   रेस्तराँ' : 'CraveOne Restaurants',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: _appState.isHindi ? 20 : 12,
            fontWeight: FontWeight.w700,
            fontFamily: 'Gilroy',
            color: Colors.white,
            shadows: const [
              Shadow(
                offset: Offset(0.5, 0.5),
                blurRadius: 2,
                color: Colors.black45,
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      // Search Button
      Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SearchScreen(),
                  ),
                );
              },
              child: const Icon(
                Icons.search,
                size: 20,
                color: Color(0xFFFF6B35),
              ),
            ),
          ),
        ),
      ),
      // Order History Button
      Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OrderHistoryScreen(),
                  ),
                );
              },
              child: const Icon(
                Icons.history,
                size: 20,
                color: Color(0xFFFF6B35),
              ),
            ),
          ),
        ),
      ),
      // Language Toggle Button
      Padding(
        padding: const EdgeInsets.only(right: 12.0),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: _appState.toggleLanguage,
              child: const Icon(
                Icons.translate,
                size: 20,
                color: Color(0xFFFF6B35),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(width: 8),
    ],
  );
}
Widget _buildCuisineSection() {
  if (_cuisines.isEmpty) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _appState.isHindi ? 'व्यंजन श्रेणियाँ' : 'Cuisine Categories',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            alignment: Alignment.center,
            child: Text(
              _appState.isHindi
                  ? 'कोई व्यंजन उपलब्ध नहीं'
                  : 'No cuisines available',
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF636E72),
              ),
            ),
          ),
        ],
      ),
    );
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            _appState.isHindi ? 'व्यंजन श्रेणियाँ' : 'Cuisine Categories',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
          ),
        ),
      ),
      const SizedBox(height: 16),
      SizedBox(
        height: 200,
        child: PageView.builder(
          controller: _cuisineController,
          itemBuilder: (context, index) {
            // Create infinite loop by using modulo operation
            final actualIndex = index % _cuisines.length;
            return _buildCuisineCard(_cuisines[actualIndex]);
          },
          onPageChanged: (index) {
            setState(() {
              _currentPage = index.toDouble();
            });
          },
        ),
      ),
      // Add page indicators
      if (_cuisines.length > 1) ...[
        const SizedBox(height: 16),
        _buildPageIndicators(),
      ],
    ],
  );
}

// Updated method to build page indicators for infinite scroll
Widget _buildPageIndicators() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_cuisines.length, (index) {
        // Calculate the current page position relative to the actual cuisine count
        double currentPageMod = _currentPage % _cuisines.length;
        double opacity = 1.0;
        double scale = 1.0;

        // Calculate distance from current page
        double distance = (currentPageMod - index).abs();
        
        // Handle wrap-around case (e.g., when at index 0 and last item is close)
        double wrapDistance = (_cuisines.length - distance).abs();
        distance = distance < wrapDistance ? distance : wrapDistance;

        if (distance < 1) {
          // Active or very close to active
          opacity = 1.0 - (distance * 0.4);
          scale = 1.0 - (distance * 0.3);
        } else {
          // Inactive
          opacity = 0.3;
          scale = 0.7;
        }

        return GestureDetector(
          onTap: () {
            // Calculate the closest page to navigate to
            double currentPage = _currentPage;
            double targetPage = currentPage - (currentPage % _cuisines.length) + index;
            
            // Choose the closest direction to reach the target
            double forwardDistance = (targetPage - currentPage).abs();
            double backwardDistance = (targetPage - _cuisines.length - currentPage).abs();
            double forwardDistance2 = (targetPage + _cuisines.length - currentPage).abs();
            
            if (backwardDistance < forwardDistance && backwardDistance < forwardDistance2) {
              targetPage = targetPage - _cuisines.length;
            } else if (forwardDistance2 < forwardDistance && forwardDistance2 < backwardDistance) {
              targetPage = targetPage + _cuisines.length;
            }
            
            _cuisineController.animateToPage(
              targetPage.round(),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 8 * scale,
            height: 8 * scale,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B35).withOpacity(opacity),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    ),
  );
}

Widget _buildCuisineCard(Cuisine cuisine) {
  return AnimatedBuilder(
    animation: _cuisineController,
    builder: (context, child) {
      double value = 1.0;
      if (_cuisineController.position.haveDimensions && _cuisineController.page != null) {
        // Calculate the actual index for infinite scroll
        double currentPage = _cuisineController.page!;
        int actualCurrentIndex = currentPage.round() % _cuisines.length;
        int cuisineIndex = _cuisines.indexOf(cuisine);
        
        // Calculate the distance considering infinite scroll
        double distance = (actualCurrentIndex - cuisineIndex).abs().toDouble();
        double wrapDistance = (_cuisines.length - distance).abs().toDouble();
        distance = distance < wrapDistance ? distance : wrapDistance;
        
        value = (1 - (distance * 0.2)).clamp(0.0, 1.0);
      }

      return Transform.scale(
        scale: value,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    CuisineDetailScreen(cuisine: cuisine),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position: animation.drive(
                      Tween(begin: const Offset(1.0, 0.0), end: Offset.zero),
                    ),
                    child: child,
                  );
                },
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  // Background Image
                  Positioned.fill(
                    child: cuisine.image.isNotEmpty
                        ? Image.network(
                            cuisine.image,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF74B9FF), Color(0xFF0984E3)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              print("Cuisine image error for ${cuisine.name}: $error");
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: _getCuisineGradient(cuisine.name),
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.restaurant_menu,
                                    size: 80,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            },
                          )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _getCuisineGradient(cuisine.name),
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.restaurant_menu,
                                size: 80,
                                color: Colors.white,
                              ),
                            ),
                          ),
                  ),

                  // Dark Overlay with Gradient
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.2),
                            Colors.black.withOpacity(0.4),
                            Colors.black.withOpacity(0.7),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Top-right favorite/bookmark icon
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.favorite_border,
                        color: Colors.grey[700],
                        size: 18,
                      ),
                    ),
                  ),

                  // Bottom content section
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.8),
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Restaurant/Cuisine name
                          Text(
                            _appState.isHindi ? cuisine.nameHindi : cuisine.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),

                          // Cuisine type and price
                          Text(
                            '${_getCuisineDescription(cuisine.name, _appState.isHindi)}',
                            style: TextStyle(
                              color: Colors.grey[300],
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),

                          // Rating and offers row
                          Row(
                            children: [
                              // Rating badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00C851),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      _getCuisineRating(cuisine.name),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),

                              // Offer text
                              Text(
                                _getCuisineOffer(cuisine.name, _appState.isHindi),
                                style: const TextStyle(
                                  color: Color(0xFFFF6B35),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
// Helper method to get cuisine-specific gradients
  List<Color> _getCuisineGradient(String cuisineName) {
    switch (cuisineName.toLowerCase()) {
      case 'italian':
        return [const Color(0xFFE17055), const Color(0xFFD63031)];
      case 'chinese':
        return [const Color(0xFFFF7675), const Color(0xFFE84393)];
      case 'indian':
        return [const Color(0xFFFFB142), const Color(0xFFFF6B35)];
      case 'mexican':
        return [const Color(0xFF00B894), const Color(0xFF00A085)];
      case 'thai':
        return [const Color(0xFF6C5CE7), const Color(0xFFA29BFE)];
      case 'japanese':
        return [const Color(0xFF74B9FF), const Color(0xFF0984E3)];
      default:
        return [const Color(0xFF74B9FF), const Color(0xFF0984E3)];
    }
  }

// Helper method to get cuisine-specific icons
  IconData _getCuisineIcon(String cuisineName) {
    switch (cuisineName.toLowerCase()) {
      case 'italian':
        return Icons.local_pizza;
      case 'chinese':
        return Icons.ramen_dining;
      case 'indian':
        return Icons.restaurant;
      case 'mexican':
        return Icons.lunch_dining;
      case 'thai':
        return Icons.rice_bowl;
      case 'japanese':
        return Icons.set_meal;
      default:
        return Icons.restaurant_menu;
    }
  }

// Helper method to get cuisine descriptions
  String _getCuisineDescription(String cuisineName, bool isHindi) {
    if (isHindi) {
      switch (cuisineName.toLowerCase()) {
        case 'italian':
          return 'पास्ता, पिज्जा और अधिक';
        case 'chinese':
          return 'नूडल्स, डम्पलिंग्स और फ्राइड राइस';
        case 'indian':
          return 'करी, बिरयानी और तंदूरी';
        case 'mexican':
          return 'टैकोस, बुरिटो और क्वेसाडिला';
        case 'thai':
          return 'पैड थाई, करी और टॉम यम';
        case 'japanese':
          return 'सुशी, रामेन और तेम्पुरा';
        default:
          return 'स्वादिष्ट व्यंजन';
      }
    } else {
      switch (cuisineName.toLowerCase()) {
        case 'italian':
          return 'Pasta, Pizza & More';
        case 'chinese':
          return 'Noodles, Dumplings & Fried Rice';
        case 'indian':
          return 'Curry, Biryani & Tandoori';
        case 'mexican':
          return 'Tacos, Burritos & Quesadillas';
        case 'thai':
          return 'Pad Thai, Curry & Tom Yum';
        case 'japanese':
          return 'Sushi, Ramen & Tempura';
        default:
          return 'Delicious Dishes';
      }
    }
  }

// Helper method to get cuisine ratings
  String _getCuisineRating(String cuisineName) {
    switch (cuisineName.toLowerCase()) {
      case 'italian':
        return '4.8';
      case 'chinese':
        return '4.6';
      case 'indian':
        return '4.7';
      case 'mexican':
        return '4.5';
      case 'thai':
        return '4.9';
      case 'japanese':
        return '4.8';
      default:
        return '4.5';
    }
  }

// Helper method to get cuisine offers
  String _getCuisineOffer(String cuisineName, bool isHindi) {
    if (isHindi) {
      switch (cuisineName.toLowerCase()) {
        case 'italian':
          return '30% छूट +3 ऑफर';
        case 'chinese':
          return '25% छूट +2 ऑफर';
        case 'indian':
          return '40% छूट +5 ऑफर';
        case 'mexican':
          return '20% छूट +1 ऑफर';
        case 'thai':
          return '35% छूट +4 ऑफर';
        case 'japanese':
          return '15% छूट +2 ऑफर';
        default:
          return '25% छूट +2 ऑफर';
      }
    } else {
      switch (cuisineName.toLowerCase()) {
        case 'italian':
          return 'Flat 30% off +3 offers';
        case 'chinese':
          return 'Flat 25% off +2 offers';
        case 'indian':
          return 'Flat 40% off +5 offers';
        case 'mexican':
          return 'Flat 20% off +1 offer';
        case 'thai':
          return 'Flat 35% off +4 offers';
        case 'japanese':
          return 'Flat 15% off +2 offers';
        default:
          return 'Flat 25% off +2 offers';
      }
    }
  }

  Widget _buildTopDishesSection() {
    if (_topDishes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _appState.isHindi ? 'टॉप 3 व्यंजन' : 'Top 3 Dishes',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3436),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              alignment: Alignment.center,
              child: Text(
                _appState.isHindi
                    ? 'कोई व्यंजन उपलब्ध नहीं'
                    : 'No dishes available',
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF636E72),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            _appState.isHindi ? 'टॉप 3 व्यंजन' : 'Top 3 Dishes',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Vertical ListView
        ListView.separated(
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(), // Let parent handle scrolling
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _topDishes.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            return _buildDishCard(_topDishes[index]);
          },
        ),
      ],
    );
  }

  Widget _buildDishCard(Dish dish) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Image Section
          Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                  child: dish.image.isNotEmpty
                      ? Image.network(
                          dish.image,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey.shade100,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade100,
                              child: const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey.shade100,
                          child: const Center(
                            child: Icon(
                              Icons.fastfood,
                              size: 40,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                ),
                // Veg Icon
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content Section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Section - Name and Favorite
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          _appState.isHindi ? dish.nameHindi : dish.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3436),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            dish.isFavorite = !dish.isFavorite;
                          });
                        },
                        child: Icon(
                          dish.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: dish.isFavorite ? Colors.red : Colors.grey,
                          size: 20,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Rating Row
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${dish.rating}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF636E72),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Bottom Section - Price and Add Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${dish.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3436),
                        ),
                      ),
                      _buildCompactAddButton(dish),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactAddButton(Dish dish) {
    int itemCount = _appState.getItemCount(dish.id);

    if (itemCount == 0) {
      return SizedBox(
        width: 80,
        height: 32,
        child: ElevatedButton(
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
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00B894),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: Text(
            _appState.isHindi ? 'जोड़ें' : 'ADD',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return Container(
      width: 80,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFF00B894),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          // Subtract Button
          Expanded(
            child: GestureDetector(
              onTap: () {
                _appState.removeFromCart(dish);
              },
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(6),
                    bottomLeft: Radius.circular(6),
                  ),
                ),
                child: const Icon(
                  Icons.remove,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),

          // Count Display
          Container(
            width: 24,
            height: 32,
            color: Colors.white,
            child: Center(
              child: Text(
                '$itemCount',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00B894),
                ),
              ),
            ),
          ),

          // Add Button
          Expanded(
            child: GestureDetector(
              onTap: () {
                _appState.addToCart(dish);
              },
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(6),
                    bottomRight: Radius.circular(6),
                  ),
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
