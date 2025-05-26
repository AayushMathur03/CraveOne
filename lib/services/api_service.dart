import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:onebanc_aayushm/models/models.dart';

class ApiService {
  static const String baseUrl = 'https://uat.onebanc.ai';
  static const String apiKey = 'uonebancservceemultrS3cg8RaL30';
  
  static Map<String, String> get headers => {
    'X-Partner-API-Key': apiKey,
    'Content-Type': 'application/json',
  };

  // Get list of cuisines and items with pagination
  static Future<ApiResponse> getItemList({int page = 1, int count = 20}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/emulator/interview/get_item_list'),
        headers: {
          ...headers,
          'X-Forward-Proxy-Action': 'get_item_list',
        },
        body: jsonEncode({
          'page': page,
          'count': count,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse.fromJson(data);
      } else {
        throw Exception('Failed to load items: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get specific item by ID
  static Future<ItemDetail> getItemById(String itemId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/emulator/interview/get_item_by_id'),
        headers: {
          ...headers,
          'X-Forward-Proxy-Action': 'get_item_by_id',
        },
        body: jsonEncode({
          'item_id': int.parse(itemId),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ItemDetail.fromJson(data);
      } else {
        throw Exception('Failed to load item: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Filter items by cuisine, price range, and rating
  static Future<FilterResponse> getItemsByFilter({
    List<String>? cuisineTypes,
    PriceRange? priceRange,
    double? minRating,
  }) async {
    try {
      Map<String, dynamic> requestBody = {};
      
      if (cuisineTypes != null && cuisineTypes.isNotEmpty) {
        requestBody['cuisine_type'] = cuisineTypes;
      }
      
      if (priceRange != null) {
        requestBody['price_range'] = {
          'min_amount': priceRange.minAmount,
          'max_amount': priceRange.maxAmount,
        };
      }
      
      if (minRating != null) {
        requestBody['min_rating'] = minRating;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/emulator/interview/get_item_by_filter'),
        headers: {
          ...headers,
          'X-Forward-Proxy-Action': 'get_item_by_filter',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return FilterResponse.fromJson(data);
      } else {
        throw Exception('Failed to filter items: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Make payment for cart items
  static Future<PaymentResponse> makePayment({
    required double totalAmount,
    required int totalItems,
    required List<PaymentItem> items,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/emulator/interview/make_payment'),
        headers: {
          ...headers,
          'X-Forward-Proxy-Action': 'make_payment',
        },
        body: jsonEncode({
          'total_amount': totalAmount.toString(),
          'total_items': totalItems,
          'data': items.map((item) => item.toJson()).toList(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PaymentResponse.fromJson(data);
      } else {
        throw Exception('Payment failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Payment error: $e');
    }
  }
}