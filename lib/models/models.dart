class Cuisine {
  final String id;
  final String name;
  final String image;
  final String nameHindi;
  final List<Dish>? items; // For API response

  Cuisine({
    required this.id,
    required this.name,
    required this.image,
    required this.nameHindi,
    this.items,
  });

  factory Cuisine.fromJson(Map<String, dynamic> json) {
    return Cuisine(
      id: json['cuisine_id'].toString(),
      name: json['cuisine_name'] ?? '',
      image: json['cuisine_image_url'] ?? '',
      nameHindi: json['cuisine_name_hindi'] ?? json['cuisine_name'] ?? '',
      items: json['items'] != null 
        ? (json['items'] as List).map((item) => Dish.fromJson(item, json['cuisine_id'].toString())).toList()
        : null,
    );
  }
}

class Dish {
  final String id;
  final String name;
  final String nameHindi;
  final String image;
  final double price;
  final double rating;
  final String cuisineId;
    bool isFavorite = false;

  Dish({
    required this.id,
    required this.name,
    required this.nameHindi,
    required this.image,
    required this.price,
    required this.rating,
    required this.cuisineId,
    required this.isFavorite,
  });

  factory Dish.fromJson(Map<String, dynamic> json, String cuisineId) {
    return Dish(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      nameHindi: json['name_hindi'] ?? json['name'] ?? '',
      image: json['image_url'] ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      rating: double.tryParse(json['rating'].toString()) ?? 0.0,
      cuisineId: cuisineId,
      isFavorite: json['is_favorite'] ?? false,
    );
  }
}

class CartItem {
  final Dish dish;
  int quantity;

  CartItem({
    required this.dish,
    this.quantity = 1,
  });

  double get totalPrice => dish.price * quantity;
}

// API Response Models
class ApiResponse {
  final int responseCode;
  final int outcomeCode;
  final String responseMessage;
  final int page;
  final int count;
  final int totalPages;
  final int totalItems;
  final List<Cuisine> cuisines;

  ApiResponse({
    required this.responseCode,
    required this.outcomeCode,
    required this.responseMessage,
    required this.page,
    required this.count,
    required this.totalPages,
    required this.totalItems,
    required this.cuisines,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      responseCode: json['response_code'] ?? 0,
      outcomeCode: json['outcome_code'] ?? 0,
      responseMessage: json['response_message'] ?? '',
      page: json['page'] ?? 1,
      count: json['count'] ?? 0,
      totalPages: json['total_pages'] ?? 0,
      totalItems: json['total_items'] ?? 0,
      cuisines: json['cuisines'] != null
        ? (json['cuisines'] as List).map((cuisine) => Cuisine.fromJson(cuisine)).toList()
        : [],
    );
  }
}

class ItemDetail {
  final int responseCode;
  final int outcomeCode;
  final String responseMessage;
  final String cuisineId;
  final String cuisineName;
  final String cuisineImageUrl;
  final String itemId;
  final String itemName;
  final double itemPrice;
  final double itemRating;
  final String itemImageUrl;

  ItemDetail({
    required this.responseCode,
    required this.outcomeCode,
    required this.responseMessage,
    required this.cuisineId,
    required this.cuisineName,
    required this.cuisineImageUrl,
    required this.itemId,
    required this.itemName,
    required this.itemPrice,
    required this.itemRating,
    required this.itemImageUrl,
  });

  factory ItemDetail.fromJson(Map<String, dynamic> json) {
    return ItemDetail(
      responseCode: json['response_code'] ?? 0,
      outcomeCode: json['outcome_code'] ?? 0,
      responseMessage: json['response_message'] ?? '',
      cuisineId: json['cuisine_id'].toString(),
      cuisineName: json['cuisine_name'] ?? '',
      cuisineImageUrl: json['cuisine_image_url'] ?? '',
      itemId: json['item_id'].toString(),
      itemName: json['item_name'] ?? '',
      itemPrice: (json['item_price'] ?? 0).toDouble(),
      itemRating: (json['item_rating'] ?? 0).toDouble(),
      itemImageUrl: json['item_image_url'] ?? '',
    );
  }

  Dish toDish() {
    return Dish(
      id: itemId,
      name: itemName,
      nameHindi: itemName, // API doesn't provide Hindi name
      image: itemImageUrl,
      price: itemPrice,
      rating: itemRating,
      cuisineId: cuisineId,
      isFavorite: false, // Default to false, can be updated later
    );
  }
}

class FilterResponse {
  final int responseCode;
  final int outcomeCode;
  final String responseMessage;
  final List<Cuisine> cuisines;

  FilterResponse({
    required this.responseCode,
    required this.outcomeCode,
    required this.responseMessage,
    required this.cuisines,
  });

  factory FilterResponse.fromJson(Map<String, dynamic> json) {
    return FilterResponse(
      responseCode: json['response_code'] ?? 0,
      outcomeCode: json['outcome_code'] ?? 0,
      responseMessage: json['response_message'] ?? '',
      cuisines: json['cuisines'] != null
        ? (json['cuisines'] as List).map((cuisine) => Cuisine.fromJson(cuisine)).toList()
        : [],
    );
  }
}

class PriceRange {
  final double minAmount;
  final double maxAmount;

  PriceRange({
    required this.minAmount,
    required this.maxAmount,
  });
}

class PaymentItem {
  final String cuisineId;
  final String itemId;
  final double itemPrice;
  final int itemQuantity;

  PaymentItem({
    required this.cuisineId,
    required this.itemId,
    required this.itemPrice,
    required this.itemQuantity,
  });

  Map<String, dynamic> toJson() {
    return {
      'cuisine_id': int.parse(cuisineId),
      'item_id': int.parse(itemId),
      'item_price': itemPrice,
      'item_quantity': itemQuantity,
    };
  }
}

class PaymentResponse {
  final int responseCode;
  final int outcomeCode;
  final String responseMessage;
  final String txnRefNo;

  PaymentResponse({
    required this.responseCode,
    required this.outcomeCode,
    required this.responseMessage,
    required this.txnRefNo,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      responseCode: json['response_code'] ?? 0,
      outcomeCode: json['outcome_code'] ?? 0,
      responseMessage: json['response_message'] ?? '',
      txnRefNo: json['txn_ref_no'] ?? '',
    );
  }
}

// models/order_history.dart
class OrderHistory {
  final String orderId;
  final String transactionRefNo;
  final DateTime orderDate;
  final List<OrderItem> items;
  final double subtotal;
  final double cgst;
  final double sgst;
  final double grandTotal;
  final int totalItems;
  final String status; // 'completed', 'pending', 'failed'

  OrderHistory({
    required this.orderId,
    required this.transactionRefNo,
    required this.orderDate,
    required this.items,
    required this.subtotal,
    required this.cgst,
    required this.sgst,
    required this.grandTotal,
    required this.totalItems,
    this.status = 'completed',
  });

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'transactionRefNo': transactionRefNo,
      'orderDate': orderDate.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'cgst': cgst,
      'sgst': sgst,
      'grandTotal': grandTotal,
      'totalItems': totalItems,
      'status': status,
    };
  }

  factory OrderHistory.fromJson(Map<String, dynamic> json) {
    return OrderHistory(
      orderId: json['orderId'],
      transactionRefNo: json['transactionRefNo'],
      orderDate: DateTime.parse(json['orderDate']),
      items: (json['items'] as List)
          .map((item) => OrderItem.fromJson(item))
          .toList(),
      subtotal: json['subtotal'].toDouble(),
      cgst: json['cgst'].toDouble(),
      sgst: json['sgst'].toDouble(),
      grandTotal: json['grandTotal'].toDouble(),
      totalItems: json['totalItems'],
      status: json['status'] ?? 'completed',
    );
  }
}

class OrderItem {
  final String dishId;
  final String dishName;
  final String dishNameHindi;
  final String dishImage;
  final double price;
  final int quantity;
  final String cuisineId;

  OrderItem({
    required this.dishId,
    required this.dishName,
    required this.dishNameHindi,
    required this.dishImage,
    required this.price,
    required this.quantity,
    required this.cuisineId,
  });

  Map<String, dynamic> toJson() {
    return {
      'dishId': dishId,
      'dishName': dishName,
      'dishNameHindi': dishNameHindi,
      'dishImage': dishImage,
      'price': price,
      'quantity': quantity,
      'cuisineId': cuisineId,
    };
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      dishId: json['dishId'],
      dishName: json['dishName'],
      dishNameHindi: json['dishNameHindi'],
      dishImage: json['dishImage'],
      price: json['price'].toDouble(),
      quantity: json['quantity'],
      cuisineId: json['cuisineId'],
    );
  }
}