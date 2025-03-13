import 'package:flutter/material.dart';

// Category data model for detection result categories
class CategoryData {
  final String detectionType;
  final String category;
  final int count;
  final List<String> ids;
  final Color? color; // Optional color for chart visualization

  CategoryData({
    required this.detectionType,
    required this.category,
    required this.count,
    required this.ids,
    this.color,
  });

  factory CategoryData.fromJson(Map<String, dynamic> json) {
    return CategoryData(
      detectionType: json['detectionType'] ?? '',
      category: json['category'] ?? '',
      count: json['ids'] != null ? (json['ids'] as List).length : 0,
      ids: json['ids'] != null ? List<String>.from(json['ids']) : [],
    );
  }

  // Get category display name (handle empty category)
  String get displayName => category.isNotEmpty ? category : '未分类';
}
