import 'package:flutter/material.dart';
import 'package:onebanc_aayushm/animated_button.dart';
import 'package:onebanc_aayushm/app_state_mgmt.dart';
import 'package:onebanc_aayushm/cart_screen.dart';
import 'package:onebanc_aayushm/data_service.dart';
import 'package:onebanc_aayushm/models/models.dart';

class CuisineDetailScreen extends StatefulWidget {
  final Cuisine cuisine;

  const CuisineDetailScreen({super.key, required this.cuisine});

  @override
  State<CuisineDetailScreen> createState() => _CuisineDetailScreenState();
}

class _CuisineDetailScreenState extends State<CuisineDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final AppState _appState = AppState();

  // State variables for async data
  List<Dish> _dishes = [];
  List<Dish> _filteredDishes = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  // Filter state variables
  bool _isVegOnly = false;
  double _minRating = 0.0;
  String _sortBy = 'name'; // 'name', 'price_low', 'price_high', 'rating'
  PriceRange? _selectedPriceRange;
  final bool _showFilterModal = false;

  // Price range options
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
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
    _appState.addListener(_updateState);
    _loadDishes();
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

  Future<void> _loadDishes() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      print(
          "Loading dishes for cuisine: ${widget.cuisine.name} (ID: ${widget.cuisine.id})");
      final dishes = await DataService.getDishesByCuisine(widget.cuisine.id);
      print("Loaded ${dishes.length} dishes for ${widget.cuisine.name}");

      if (mounted) {
        setState(() {
          _dishes = dishes;
          _filteredDishes = dishes;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading dishes: $e");
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _applyFilters() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Prepare filter parameters
      List<String>? cuisineTypes = [widget.cuisine.id];
      PriceRange? priceRange = _selectedPriceRange;
      double? minRating = _minRating > 0 ? _minRating : null;

      // Call the filter API
      List<Dish> filteredDishes = await DataService.filterDishes(
        cuisineTypes: cuisineTypes,
        priceRange: priceRange,
        minRating: minRating,
      );

      // Apply sorting
      _sortDishes(filteredDishes);

      if (mounted) {
        setState(() {
          _filteredDishes = filteredDishes;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error applying filters: $e");
      // Fallback to local filtering
      _applyLocalFilters();
    }
  }

  void _applyLocalFilters() {
    List<Dish> filtered = List.from(_dishes);

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
    _sortDishes(filtered);

    setState(() {
      _filteredDishes = filtered;
      _isLoading = false;
    });
  }

  void _sortDishes(List<Dish> dishes) {
    switch (_sortBy) {
      case 'price_low':
        dishes.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_high':
        dishes.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'rating':
        dishes.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'name':
      default:
        dishes.sort((a, b) => a.name.compareTo(b.name));
        break;
    }
  }

  void _resetFilters() {
    setState(() {
      _isVegOnly = false;
      _minRating = 0.0;
      _sortBy = 'name';
      _selectedPriceRange = null;
      _filteredDishes = _dishes;
    });

      _applyFilters(); 
  }

  Future<void> refreshData() async {
    await DataService.refreshData();
    await _loadDishes();
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFilterBottomSheet(),
    );
  }

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildSortBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: refreshData,
          color: const Color(0xFFFF6B35),
          backgroundColor: Colors.white,
          displacement: 40,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _buildCurvedHeader(),
              ),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    _buildContent(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton:
          _appState.totalItemsInCart > 0 ? _buildFloatingCartButton() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildCurvedHeader() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.5,
      child: Stack(
        children: [
          // Background image with overlay
          Container(
            height: MediaQuery.of(context).size.height * 0.5,
            decoration: BoxDecoration(
              image: widget.cuisine.image.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(widget.cuisine.image),
                      fit: BoxFit.cover,
                    )
                  : null,
              gradient: widget.cuisine.image.isEmpty
                  ? const LinearGradient(
                      colors: [Color(0xFFB85C38), Color(0xFF8B4513)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.black.withOpacity(0.3),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Curved bottom shape
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 50,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top navigation bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back,
                            color: Colors.white, size: 24),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedButton(
                            onPressed: _appState.toggleLanguage,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            child: Text(
                              _appState.isHindi ? 'English' : 'हिंदी',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Main content
                  Flexible(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _appState.isHindi ? 'सबसे लोकप्रिय' : 'MOST LOVED IN',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              (_appState.isHindi
                                      ? widget.cuisine.nameHindi
                                      : widget.cuisine.name)
                                  .toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _appState.isHindi
                              ? 'लोकप्रिय व्यंजन खोजें\nजिन्हें आपने पहले नहीं आज़माया है'
                              : 'Explore popular dishes\nyou\'ve not tried before',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                            height: 1.3,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                        ),
                        if (!_isLoading &&
                            !_hasError &&
                            _filteredDishes.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.3)),
                            ),
                            child: Text(
                              _appState.isHindi
                                  ? '${_filteredDishes.length} व्यंजन उपलब्ध'
                                  : '${_filteredDishes.length} dishes available',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
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

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingState();
    } else if (_hasError) {
      return _buildErrorState();
    } else if (_filteredDishes.isEmpty) {
      return _buildEmptyState();
    } else {
      return Column(
        children: [
          _buildFilterSection(),
          const SizedBox(height: 16),
          _buildDishesGrid(_filteredDishes),
        ],
      );
    }
  }

  Widget _buildFilterSection() {
    bool hasActiveFilters =
        _isVegOnly || _minRating > 0 || _selectedPriceRange != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  _appState.isHindi ? 'फिल्टर' : 'Filter',
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
                  _appState.isHindi ? 'शुद्ध शाकाहारी' : 'Pure Veg',
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
                    '${_appState.isHindi ? 'रेटिंग' : 'Rating'} ${_minRating.toStringAsFixed(1)}+',
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
                  child: Text(
                    _appState.isHindi
                        ? 'सभी फिल्टर हटाएं'
                        : 'Clear all filters',
                    style: const TextStyle(
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
        return _appState.isHindi ? 'कम कीमत' : 'Price: Low to High';
      case 'price_high':
        return _appState.isHindi ? 'अधिक कीमत' : 'Price: High to Low';
      case 'rating':
        return _appState.isHindi ? 'रेटिंग' : 'Rating';
      case 'name':
      default:
        return _appState.isHindi ? 'नाम' : 'Name';
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
                      Text(
                        _appState.isHindi ? 'फिल्टर' : 'Filters',
                        style: const TextStyle(
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

                  // Rating Filter - Changed from slider to tappable chips
                  Text(
                    _appState.isHindi ? 'न्यूनतम रेटिंग' : 'Minimum Rating',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildRatingChip(0.0,
                          _appState.isHindi ? 'कोई भी' : 'Any', setModalState),
                      _buildRatingChip(3.0, '3.0+', setModalState),
                      _buildRatingChip(3.5, '3.5+', setModalState),
                      _buildRatingChip(4.0, '4.0+', setModalState),
                      _buildRatingChip(4.5, '4.5+', setModalState),
                      _buildRatingChip(5.0, '5.0', setModalState),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Price Range Filter
                  Text(
                    _appState.isHindi ? 'कीमत सीमा' : 'Price Range',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildPriceRangeChip(null,
                          _appState.isHindi ? 'कोई भी' : 'Any', setModalState),
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
                      child: Text(
                        _appState.isHindi
                            ? 'फिल्टर लागू करें'
                            : 'Apply Filters',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                ]);
          },
        ),
      ),
    );
  }

  // Updated method for rating chips with setModalState parameter
  Widget _buildRatingChip(
      double rating, String label, StateSetter setModalState) {
    bool isSelected = _minRating == rating;

    return GestureDetector(
      onTap: () {
        setState(() {
          _minRating = rating;
        });
        setModalState(() {}); // This rebuilds the bottom sheet
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
        setModalState(() {}); // This rebuilds the bottom sheet
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
      {'key': 'name', 'label': _appState.isHindi ? 'नाम' : 'Name'},
      {
        'key': 'price_low',
        'label': _appState.isHindi ? 'कम कीमत' : 'Price: Low to High'
      },
      {
        'key': 'price_high',
        'label': _appState.isHindi ? 'अधिक कीमत' : 'Price: High to Low'
      },
      {'key': 'rating', 'label': _appState.isHindi ? 'रेटिंग' : 'Rating'},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _appState.isHindi ? 'सॉर्ट करें' : 'Sort by',
            style: const TextStyle(
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

  // Widget for "No dishes found" screen with clear filter option
  Widget _buildNoDishesFound() {
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
            _appState.isHindi ? 'कोई व्यंजन नहीं मिला' : 'No dishes found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _appState.isHindi
                ? 'आपके फिल्टर के अनुसार कोई व्यंजन उपलब्ध नहीं है'
                : 'No dishes match your current filters',
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
              label: Text(
                _appState.isHindi ? 'फिल्टर साफ करें' : 'Clear Filters',
              ),
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

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
            ),
            const SizedBox(height: 16),
            Text(
              _appState.isHindi
                  ? 'व्यंजन लोड हो रहे हैं...'
                  : 'Loading dishes...',
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF636E72),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 40,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _appState.isHindi ? 'कुछ गलत हो गया' : 'Something went wrong',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3436),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF636E72),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            AnimatedButton(
              onPressed: _loadDishes,
              backgroundColor: const Color(0xFFFF6B35),
              child: Text(
                _appState.isHindi ? 'फिर से कोशिश करें' : 'Try Again',
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

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.restaurant_menu,
                size: 40,
                color: Color(0xFFFF6B35),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _appState.isHindi
                  ? 'कोई व्यंजन उपलब्ध नहीं'
                  : 'No dishes available',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3436),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _appState.isHindi
                  ? 'इस व्यंजन श्रेणी में अभी कोई व्यंजन नहीं हैं।'
                  : 'There are no dishes in this cuisine category yet.',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF636E72),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDishesGrid(List<Dish> dishes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            _appState.isHindi
                ? 'व्यंजन (${dishes.length})'
                : 'Dishes (${dishes.length})',
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
          itemCount: dishes.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            return _buildDishCard(dishes[index]);
          },
        ),
      ],
    );
  }

  Widget _buildDishCard(Dish dish) {
    final itemCount = _appState.getItemCount(dish.id);

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
                            if (loadingProgress == null) {
                              return child;
                            }
                            return Container(
                              color: Colors.grey.shade100,
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.grey.shade600,
                                  ),
                                ),
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
