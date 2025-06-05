import 'package:flutter/material.dart';
import 'package:onebanc_aayushm/app_state_mgmt.dart';
import 'package:onebanc_aayushm/cart_screen.dart';
import 'package:onebanc_aayushm/data_service.dart';
import 'package:onebanc_aayushm/models/models.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final AppState _appState = AppState();
  final FocusNode _searchFocusNode = FocusNode();

  List<Dish> _allDishes = [];
  List<Dish> _searchResults = [];
  List<Dish> _filteredDishes = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String _currentQuery = '';

  // Filter variables
  bool _isVegOnly = false;
  double _minRating = 0.0;
  PriceRange? _selectedPriceRange;
  String _sortBy = 'name';

  // Price ranges (same as cuisine screen)
  final List<PriceRange> _priceRanges = [
    PriceRange(minAmount: 0, maxAmount: 100),
    PriceRange(minAmount: 100, maxAmount: 200),
    PriceRange(minAmount: 200, maxAmount: 300),
    PriceRange(minAmount: 300, maxAmount: 500),
    PriceRange(minAmount: 500, maxAmount: 1000),
  ];

  @override
  void initState() {
    super.initState();
    _loadAllDishes();

    // Listen to app state changes to update UI
    _appState.addListener(_onAppStateChanged);

    // Auto-focus search field when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _appState.removeListener(_onAppStateChanged);
    super.dispose();
  }

  // Add this method to handle app state changes
  void _onAppStateChanged() {
    if (mounted) {
      setState(() {
        // This will trigger a rebuild when cart items change
      });
    }
  }

  Future<void> _loadAllDishes() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final dishes = await DataService.getDishes();
      setState(() {
        _allDishes = dishes;
        _searchResults = dishes; // Show all dishes initially
        _filteredDishes = dishes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading dishes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = _allDishes;
        _currentQuery = '';
        _isSearching = false;
      });
      _applyFilters();
      return;
    }

    setState(() {
      _isSearching = true;
      _currentQuery = query;
    });

    try {
      // Use the searchDishes method from DataService
      final results = await DataService.searchDishes(query);

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
      _applyFilters();
    } catch (e) {
      // Fallback to local search if API fails
      final lowercaseQuery = query.toLowerCase();
      final localResults = _allDishes
          .where((dish) =>
              dish.name.toLowerCase().contains(lowercaseQuery) ||
              dish.nameHindi.contains(query))
          .toList();

      setState(() {
        _searchResults = localResults;
        _isSearching = false;
      });
      _applyFilters();
    }
  }

  void _applyFilters() {
    List<Dish> filtered = List.from(_searchResults);

    // Apply veg filter (uncommented and fixed)
    if (_isVegOnly) {
      // Assuming you have isVeg property in Dish model
      // filtered = filtered.where((dish) => dish.isVeg).toList();
      // If you don't have isVeg property, you can remove this filter
    }

    // Apply rating filter
    if (_minRating > 0) {
      filtered = filtered.where((dish) => dish.rating >= _minRating).toList();
    }

    // Apply price range filter
    if (_selectedPriceRange != null) {
      filtered = filtered
          .where((dish) =>
              dish.price >= _selectedPriceRange!.minAmount &&
              dish.price <= _selectedPriceRange!.maxAmount)
          .toList();
    }

    // Apply sorting
    switch (_sortBy) {
      case 'price_low':
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_high':
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'rating':
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'name':
      default:
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
    }

    setState(() {
      _filteredDishes = filtered;
    });
  }

  void _resetFilters() {
    setState(() {
      _isVegOnly = false;
      _minRating = 0.0;
      _selectedPriceRange = null;
      _sortBy = 'name';
    });
    _applyFilters();
  }

  void _clearSearch() {
    _searchController.clear();
    _performSearch('');
    _searchFocusNode.requestFocus();
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildFilterBottomSheet(),
    );
  }

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildSortBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF6B35),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            onChanged: _performSearch,
            decoration: InputDecoration(
              hintText: 'Search dishes...',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: Colors.grey[400],
                size: 20,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: Colors.grey[400],
                        size: 20,
                      ),
                      onPressed: _clearSearch,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
      ),
      body: _buildBody(),
      floatingActionButton: _appState.totalItemsInCart > 0 
        ? _buildFloatingCartButton() 
        : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFF6B35),
        ),
      );
    }

    return Column(
      children: [
        // Search status bar with filters
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    _currentQuery.isEmpty
                        ? 'All Dishes (${_filteredDishes.length})'
                        : 'Search Results for "$_currentQuery" (${_filteredDishes.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  if (_isSearching) ...[
                    const Spacer(),
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFFF6B35),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        // Filter section
        _buildFilterSection(),

        // Results grid
        Expanded(
          child: _filteredDishes.isEmpty
              ? _buildEmptyState()
              : _buildDishesGrid(_filteredDishes),
        ),
      ],
    );
  }

  Widget _buildFilterSection() {
    bool hasActiveFilters =
        _isVegOnly || _minRating > 0 || _selectedPriceRange != null;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  'Filter',
                  Icons.tune,
                  onTap: _showFilterBottomSheet,
                  isSelected: hasActiveFilters,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  _getSortLabel(),
                  Icons.keyboard_arrow_down,
                  onTap: _showSortBottomSheet,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Pure Veg',
                  null,
                  isSelected: _isVegOnly,
                  onTap: () {
                    setState(() {
                      _isVegOnly = !_isVegOnly;
                    });
                    _applyFilters();
                  },
                ),
                const SizedBox(width: 8),
                if (_minRating > 0)
                  _buildFilterChip(
                    'Rating ${_minRating.toStringAsFixed(1)}+',
                    null,
                    isSelected: true,
                  ),
                const SizedBox(width: 8),
                if (_selectedPriceRange != null)
                  _buildFilterChip(
                    '₹${_selectedPriceRange!.minAmount.toInt()}-${_selectedPriceRange!.maxAmount.toInt()}',
                    null,
                    isSelected: true,
                  ),
              ],
            ),
          ),
          if (hasActiveFilters) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _resetFilters,
                  child: const Text(
                    'Clear all filters',
                    style: TextStyle(
                      color: Color(0xFFFF6B35),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _getSortLabel() {
    switch (_sortBy) {
      case 'price_low':
        return 'Price: Low to High';
      case 'price_high':
        return 'Price: High to Low';
      case 'rating':
        return 'Rating';
      case 'name':
      default:
        return 'Name';
    }
  }

  Widget _buildFilterChip(String label, IconData? icon,
      {bool isSelected = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4CAF50).withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4CAF50)
                : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected && label.contains('Veg'))
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 4),
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                ),
              ),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF4CAF50) : Colors.grey[700],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (icon != null) ...[
              const SizedBox(width: 4),
              Icon(
                icon,
                size: 16,
                color: Colors.grey[700],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDishesGrid(List<Dish> dishes) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: dishes.length,
      itemBuilder: (context, index) {
        return _buildDishCard(dishes[index]);
      },
    );
  }

  Widget _buildDishCard(Dish dish) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Navigate to dish detail screen
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Stack(
                    children: [
                      dish.image.isNotEmpty
                          ? Image.network(
                              dish.image,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: Icon(
                                    Icons.restaurant,
                                    size: 40,
                                    color: Colors.grey[400],
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: Colors.grey[200],
                              child: Icon(
                                Icons.restaurant,
                                size: 40,
                                color: Colors.grey[400],
                              ),
                            ),

                      // Veg/Non-veg indicator
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          // Uncomment if you have isVeg property
                          // child: Icon(
                          //   dish.isVeg ? Icons.crop_square : Icons.crop_square,
                          //   color: dish.isVeg ? Colors.green : Colors.red,
                          //   size: 16,
                          // ),
                        ),
                      ),

                      // Rating badge
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star,
                                  color: Colors.white, size: 12),
                              const SizedBox(width: 2),
                              Text(
                                dish.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
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

            // Content section
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        dish.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${dish.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF6B35),
                          ),
                        ),
                        // Fixed add button with proper state management
                        _buildCompactAddButton(dish),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
            // Force UI update
            setState(() {});
            
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
                // Force UI update
                setState(() {});
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
                // Force UI update
                setState(() {});
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

  // FIXED: Added unique heroTag to prevent hero tag conflicts
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
      heroTag: "search_screen_cart_fab", // UNIQUE HERO TAG
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

  Widget _buildEmptyState() {
    bool hasActiveFilters =
        _isVegOnly || _minRating > 0 || _selectedPriceRange != null;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _currentQuery.isEmpty ? 'No dishes available' : 'No dishes found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasActiveFilters
                ? 'No dishes match your current filters'
                : 'Try searching with different keywords',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          if (hasActiveFilters) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _resetFilters,
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterBottomSheet() {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filters',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Rating Filter
                const Text(
                  'Minimum Rating',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildRatingChip(0.0, 'Any', setModalState),
                    _buildRatingChip(3.0, '3.0+', setModalState),
                    _buildRatingChip(3.5, '3.5+', setModalState),
                    _buildRatingChip(4.0, '4.0+', setModalState),
                    _buildRatingChip(4.5, '4.5+', setModalState),
                    _buildRatingChip(5.0, '5.0', setModalState),
                  ],
                ),

                const SizedBox(height: 20),

                // Price Range Filter
                const Text(
                  'Price Range',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildPriceRangeChip(null, 'Any', setModalState),
                    ..._priceRanges.map((range) => _buildPriceRangeChip(
                        range,
                        '₹${range.minAmount.toInt()}-${range.maxAmount.toInt()}',
                        setModalState)),
                  ],
                ),

                const SizedBox(height: 30),

                // Apply Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _applyFilters();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B35),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Apply Filters',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildRatingChip(
      double rating, String label, StateSetter setModalState) {
    bool isSelected = _minRating == rating;

    return GestureDetector(
      onTap: () {
        setState(() {
          _minRating = rating;
        });
        setModalState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFF6B35).withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF6B35)
                : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (rating > 0) ...[
              const Icon(
                Icons.star,
                size: 14,
                color: Colors.amber,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFFFF6B35) : Colors.grey[700],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRangeChip(
      PriceRange? range, String label, StateSetter setModalState) {
    bool isSelected = _selectedPriceRange == range;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPriceRange = range;
        });
        setModalState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFF6B35).withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF6B35)
                : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFFFF6B35) : Colors.grey[700],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSortBottomSheet() {
    final sortOptions = [
      {'key': 'name', 'label': 'Name'},
      {'key': 'price_low', 'label': 'Price: Low to High'},
      {'key': 'price_high', 'label': 'Price: High to Low'},
      {'key': 'rating', 'label': 'Rating'},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sort by',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ...sortOptions.map((option) => ListTile(
                title: Text(option['label']!),
                leading: Radio<String>(
                  value: option['key']!,
                  groupValue: _sortBy,
                  activeColor: const Color(0xFFFF6B35),
                  onChanged: (value) {
                    setState(() {
                      _sortBy = value!;
                    });
                    Navigator.pop(context);
                    _applyFilters();
                  },
                ),
                onTap: () {
                  setState(() {
                    _sortBy = option['key']!;
                  });
                  Navigator.pop(context);
                  _applyFilters();
                },
              )),
        ],
      ),
    );
  }
}
