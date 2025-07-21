import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/category_model.dart';

class CategoryService extends ChangeNotifier {
  static const String _categoryApiUrl = 'http://47.119.178.225:8090/api/v5/detector/result/category';
  static const String _token = '0c97a6b8-9142-486c-a304-83a3e745614b';
  static const bool _debugMode = true; // Enable debug output
  
  List<CategoryData> _riskCategories = [];
  List<CategoryData> _aiCategories = [];
  bool _isLoading = false;
  String _error = '';
  
  List<CategoryData> get riskCategories => _riskCategories;
  List<CategoryData> get aiCategories => _aiCategories;
  bool get isLoading => _isLoading;
  String get error => _error;
  
  // Debug print function
  static void _debugPrint(String message) {
    if (_debugMode) {
      print(message);
    }
  }
  
  // Initialize the service by fetching both category types
  Future<void> initialize() async {
    await fetchBothCategories();
  }
  
  // Fetch both RISK and AI categories
  Future<void> fetchBothCategories() async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    
    try {
      // Fetch both types in parallel
      final results = await Future.wait([
        fetchCategories('RISK'),
        fetchCategories('AI'),
      ]);
      
      _riskCategories = results[0];
      _aiCategories = results[1];
      
      // Assign colors to categories for visualization
      _assignColorsToCategories();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error fetching categories: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Assign colors to categories for visualization
  void _assignColorsToCategories() {
    // Define a list of colors for the chart
    final List<Color> colorPalette = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.indigo,
      Colors.cyan,
    ];
    
    // Assign colors to RISK categories
    for (int i = 0; i < _riskCategories.length; i++) {
      final color = colorPalette[i % colorPalette.length];
      _riskCategories[i] = CategoryData(
        detectionType: _riskCategories[i].detectionType,
        category: _riskCategories[i].category,
        count: _riskCategories[i].count,
        ids: _riskCategories[i].ids,
        color: color,
      );
    }
    
    // Assign colors to AI categories
    for (int i = 0; i < _aiCategories.length; i++) {
      final color = colorPalette[i % colorPalette.length];
      _aiCategories[i] = CategoryData(
        detectionType: _aiCategories[i].detectionType,
        category: _aiCategories[i].category,
        count: _aiCategories[i].count,
        ids: _aiCategories[i].ids,
        color: color,
      );
    }
  }
  
  /// Fetch detection result categories
  /// 
  /// [detectionType] - Detection type, either 'RISK' or 'AI'
  /// Returns a list of category data if successful, an empty list otherwise
  Future<List<CategoryData>> fetchCategories(String detectionType) async {
    try {
      _debugPrint('获取分类数据: $detectionType');
      
      // Prepare the request body
      final Map<String, dynamic> requestBody = {
        'token': _token,
        'data': {
          'detectionType': detectionType
        }
      };
      
      // Make the API call
      final response = await http.post(
        Uri.parse(_categoryApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json; charset=utf-8',
        },
        body: jsonEncode(requestBody),
      );
      
      _debugPrint('分类API响应状态: ${response.statusCode}');
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Decode the response with UTF-8 to handle Chinese characters properly
        final decodedResponse = utf8.decode(response.bodyBytes);
        _debugPrint('分类API响应体: $decodedResponse');
        
        // Parse the properly decoded response
        final Map<String, dynamic> data = jsonDecode(decodedResponse);
        
        if (data['code'] == 'SUCCESS' && data['data'] is List) {
          final List<dynamic> categoryList = data['data'];
          
          // Convert the response to CategoryData objects
          return categoryList.map((category) {
            return CategoryData(
              detectionType: category['detectionType'] ?? detectionType,
              category: category['category'] ?? '',
              count: (category['ids'] as List<dynamic>).length,
              ids: (category['ids'] as List<dynamic>).cast<String>(),
            );
          }).toList();
        }
      }
      
      // Return empty list on failure
      return [];
    } catch (e) {
      _debugPrint('Error fetching categories: $e');
      return [];
    }
  }
  
  // Helper method to prettify JSON for display (useful for debugging)
  static String prettyPrintJson(Map<String, dynamic> json) {
    final encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(json);
  }
}
