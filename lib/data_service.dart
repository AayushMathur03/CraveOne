import 'package:onebanc_aayushm/models/models.dart';
import 'package:onebanc_aayushm/services/api_service.dart';

class DataService {
  // Cache for storing fetched data
  static List<Cuisine> _cachedCuisines = [];
  static List<Dish> _cachedDishes = [];
  static bool _isDataLoaded = false;

  // Load initial data from API
  static Future<void> loadInitialData() async {
    if (_isDataLoaded) return;
    
    try {
      final response = await ApiService.getItemList(page: 1, count: 100);
      _cachedCuisines = response.cuisines;
      print("Available Cuisines: ${_cachedCuisines.length}");
      
      // Extract all dishes from cuisines
      _cachedDishes = [];
      for (var cuisine in _cachedCuisines) {
        if (cuisine.items != null) {
          _cachedDishes.addAll(cuisine.items!);
        }
      }
      
      _isDataLoaded = true;
    } catch (e) {
      throw Exception('Failed to load initial data: $e');
    }
  }

  // Get all cuisines
  static Future<List<Cuisine>> getCuisines() async {
    if (!_isDataLoaded) {
      await loadInitialData();
    }
    return _cachedCuisines;
  }

  // Get all dishes
  static Future<List<Dish>> getDishes() async {
    if (!_isDataLoaded) {
      await loadInitialData();
    }
    return _cachedDishes;
  }

  // Get dishes by cuisine ID
  static Future<List<Dish>> getDishesByCuisine(String cuisineId) async {
    final dishes = await getDishes();
    return dishes.where((dish) => dish.cuisineId == cuisineId).toList();
  }

  // Get top dishes based on rating
  static Future<List<Dish>> getTopDishes() async {
    final dishes = await getDishes();
    var sortedDishes = List<Dish>.from(dishes);
    sortedDishes.sort((a, b) => b.rating.compareTo(a.rating));
    return sortedDishes.take(3).toList();
  }

  // Get cuisine by ID
  static Future<Cuisine?> getCuisineById(String id) async {
    final cuisines = await getCuisines();
    try {
      return cuisines.firstWhere((cuisine) => cuisine.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get dish by ID (from API)
  static Future<Dish?> getDishById(String id) async {
    try {
      final itemDetail = await ApiService.getItemById(id);
      return itemDetail.toDish();
    } catch (e) {
      // Fallback to cached data
      final dishes = await getDishes();
      try {
        return dishes.firstWhere((dish) => dish.id == id);
      } catch (e) {
        return null;
      }
    }
  }

  // Search dishes by name
  static Future<List<Dish>> searchDishes(String query) async {
    final dishes = await getDishes();
    final lowercaseQuery = query.toLowerCase();
    return dishes.where((dish) => 
      dish.name.toLowerCase().contains(lowercaseQuery) ||
      dish.nameHindi.contains(query)
    ).toList();
  }

  // Filter dishes using API
  static Future<List<Dish>> filterDishes({
    List<String>? cuisineTypes,
    PriceRange? priceRange,
    double? minRating,
  }) async {
    try {
      final response = await ApiService.getItemsByFilter(
        cuisineTypes: cuisineTypes,
        priceRange: priceRange,
        minRating: minRating,
      );
      
      List<Dish> filteredDishes = [];
      for (var cuisine in response.cuisines) {
        if (cuisine.items != null) {
          filteredDishes.addAll(cuisine.items!);
        }
      }
      return filteredDishes;
    } catch (e) {
      // Fallback to local filtering
      final dishes = await getDishes();
      return dishes.where((dish) {
        bool matchesCuisine = cuisineTypes == null || 
          cuisineTypes.isEmpty || 
          cuisineTypes.contains(dish.cuisineId);
        
        bool matchesPrice = priceRange == null || 
          (dish.price >= priceRange.minAmount && dish.price <= priceRange.maxAmount);
        
        bool matchesRating = minRating == null || dish.rating >= minRating;
        
        return matchesCuisine && matchesPrice && matchesRating;
      }).toList();
    }
  }

  // Get dishes by price range
  static Future<List<Dish>> getDishesByPriceRange(double minPrice, double maxPrice) async {
    return await filterDishes(
      priceRange: PriceRange(minAmount: minPrice, maxAmount: maxPrice),
    );
  }

  // Get highest rated dishes
  static Future<List<Dish>> getHighestRatedDishes({double minRating = 4.0}) async {
    return await filterDishes(minRating: minRating);
  }

  // Refresh data from API
  static Future<void> refreshData() async {
    _isDataLoaded = false;
    _cachedCuisines.clear();
    _cachedDishes.clear();
    await loadInitialData();
  }

  // Make payment
  static Future<PaymentResponse> makePayment({
    required double totalAmount,
    required int totalItems,
    required List<CartItem> cartItems,
  }) async {
    List<PaymentItem> paymentItems = cartItems.map((cartItem) => PaymentItem(
      cuisineId: cartItem.dish.cuisineId,
      itemId: cartItem.dish.id,
      itemPrice: cartItem.dish.price,
      itemQuantity: cartItem.quantity,
    )).toList();

    return await ApiService.makePayment(
      totalAmount: totalAmount,
      totalItems: totalItems,
      items: paymentItems,
    );
  }



}