// ------------------------------------------------------------------
// File: food_entry.dart
// Feature: Food
// Description: Domain model representing a single logged food item.
// ------------------------------------------------------------------
import 'package:cloud_firestore/cloud_firestore.dart';

class FoodEntry {
  final String id;
  final String name;
  final int calories;
  final String servingSize;
  final DateTime timestamp;

  FoodEntry({
    required this.id,
    required this.name,
    required this.calories,
    required this.servingSize,
    required this.timestamp,
  });

  factory FoodEntry.fromJson(Map<String, dynamic> json, String id) {
    return FoodEntry(
      id: id,
      name: json['name'] as String? ?? '',
      calories: json['calories'] as int? ?? 0,
      servingSize: json['servingSize'] as String? ?? '',
      timestamp: (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'calories': calories,
      'servingSize': servingSize,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
