// ------------------------------------------------------------------
// File: food_entry.dart
// Feature: Food
// Description: Domain model representing a single logged food item.
// ------------------------------------------------------------------
import 'package:cloud_firestore/cloud_firestore.dart';

class FoodEntry {
  final String id;
  final String name;
  final int quantity;
  final String unit;
  final int caloriesPerUnit;
  final int proteinPerUnit;
  final int carbsPerUnit;
  final int fatPerUnit;
  final int totalCalories;
  final int totalProtein;
  final int totalCarbs;
  final int totalFat;
  final DateTime timestamp;

  FoodEntry({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.caloriesPerUnit,
    required this.proteinPerUnit,
    required this.carbsPerUnit,
    required this.fatPerUnit,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.timestamp,
  });

  factory FoodEntry.fromJson(Map<String, dynamic> json, String id) {
    final legacyServing = json['servingSize'] as String?;
    var quantity = json['quantity'] as int? ?? 1;
    var unit = json['unit'] as String? ?? 'serving';
    if (json['quantity'] == null &&
        legacyServing != null &&
        legacyServing.isNotEmpty) {
      unit = legacyServing;
    }
    final totalCalories =
        json['totalCalories'] as int? ?? json['calories'] as int? ?? 0;
    final totalProtein = json['totalProtein'] as int? ?? 0;
    final totalCarbs = json['totalCarbs'] as int? ?? 0;
    final totalFat = json['totalFat'] as int? ?? 0;
    final caloriesPerUnit =
        json['caloriesPerUnit'] as int? ??
        (quantity > 0 ? (totalCalories / quantity).round() : 0);
    final proteinPerUnit =
        json['proteinPerUnit'] as int? ??
        (quantity > 0 ? (totalProtein / quantity).round() : 0);
    final carbsPerUnit =
        json['carbsPerUnit'] as int? ??
        (quantity > 0 ? (totalCarbs / quantity).round() : 0);
    final fatPerUnit =
        json['fatPerUnit'] as int? ??
        (quantity > 0 ? (totalFat / quantity).round() : 0);

    return FoodEntry(
      id: id,
      name: json['name'] as String? ?? '',
      quantity: quantity,
      unit: unit,
      caloriesPerUnit: caloriesPerUnit,
      proteinPerUnit: proteinPerUnit,
      carbsPerUnit: carbsPerUnit,
      fatPerUnit: fatPerUnit,
      totalCalories: totalCalories,
      totalProtein: totalProtein,
      totalCarbs: totalCarbs,
      totalFat: totalFat,
      timestamp: (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'caloriesPerUnit': caloriesPerUnit,
      'proteinPerUnit': proteinPerUnit,
      'carbsPerUnit': carbsPerUnit,
      'fatPerUnit': fatPerUnit,
      'totalCalories': totalCalories,
      'totalProtein': totalProtein,
      'totalCarbs': totalCarbs,
      'totalFat': totalFat,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
