// ------------------------------------------------------------------
// File: food_repository.dart
// Feature: Food
// Description: Centralizes all Firebase Firestore calls for the food tracker.
// ------------------------------------------------------------------
import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../../../shared/utils/app_logger.dart';
import '../models/daily_goals.dart';
import '../models/food_entry.dart';

class FoodRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  /// Adds a new food entry to the user's food_entries collection.
  Future<void> addFoodEntry(FoodEntry entry) async {
    if (_uid == null) {
      AppLogger.d(
        'FoodRepository',
        'addFoodEntry failed: no authenticated user',
      );
      throw Exception('User not logged in');
    }

    AppLogger.d(
      'FoodRepository',
      'Writing food entry to Firestore: "${entry.name}" (${entry.caloriesPerUnit} kcal) for uid=$_uid',
    );
    try {
      await _firestore
          .collection('users')
          .doc(_uid)
          .collection('food_entries')
          .add(entry.toJson());
      AppLogger.d('FoodRepository', 'Food entry written successfully');
    } catch (e, st) {
      AppLogger.d(
        'FoodRepository',
        'addFoodEntry Firestore write failed',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Fetches food entries for the current day.
  Future<List<FoodEntry>> getDailyFoodEntries() async {
    if (_uid == null) {
      AppLogger.d(
        'FoodRepository',
        'getDailyFoodEntries failed: no authenticated user',
      );
      throw Exception('User not logged in');
    }

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    AppLogger.d(
      'FoodRepository',
      'Querying food_entries for uid=$_uid date=${now.year}-${now.month}-${now.day}',
    );
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_uid)
          .collection('food_entries')
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .orderBy('timestamp', descending: true)
          .get();

      final entries = snapshot.docs
          .map((doc) => FoodEntry.fromJson(doc.data(), doc.id))
          .toList();
      AppLogger.d(
        'FoodRepository',
        'getDailyFoodEntries returned ${entries.length} entries',
      );
      return entries;
    } catch (e, st) {
      AppLogger.d(
        'FoodRepository',
        'getDailyFoodEntries Firestore query failed',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  Future<List<FoodEntry>> getFoodCatalogEntries() async {
    if (_uid == null) {
      AppLogger.d(
        'FoodRepository',
        'getFoodCatalogEntries failed: no authenticated user',
      );
      throw Exception('User not logged in');
    }

    AppLogger.d('FoodRepository', 'Fetching food catalog for uid=$_uid');
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_uid)
          .collection('food_entries')
          .orderBy('timestamp', descending: true)
          .get();

      final catalogByName = <String, FoodEntry>{};
      for (final doc in snapshot.docs) {
        final entry = FoodEntry.fromJson(doc.data(), doc.id);
        final key = _catalogKey(entry.name);
        if (key.isEmpty || catalogByName.containsKey(key)) {
          continue;
        }
        catalogByName[key] = entry;
      }

      final catalog = catalogByName.values.toList();
      AppLogger.d(
        'FoodRepository',
        'Food catalog loaded: ${catalog.length} unique foods',
      );
      return catalog;
    } catch (e, st) {
      AppLogger.d(
        'FoodRepository',
        'getFoodCatalogEntries Firestore query failed',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Retrieves the user's daily goals.
  Future<DailyGoals> getDailyGoals() async {
    if (_uid == null) {
      AppLogger.d(
        'FoodRepository',
        'getDailyGoals failed: no authenticated user',
      );
      throw Exception('User not logged in');
    }

    AppLogger.d('FoodRepository', 'Fetching daily goals for uid=$_uid');
    try {
      final doc = await _firestore
          .collection('users')
          .doc(_uid)
          .collection('goals')
          .doc('daily_food')
          .get();

      if (!doc.exists || doc.data() == null) {
        AppLogger.d(
          'FoodRepository',
          'No goals doc found, returning defaults (2000 kcal / 100g protein)',
        );
        return DailyGoals(targetCalories: 2000, targetProtein: 100);
      }

      final goals = DailyGoals.fromJson(doc.data()!);
      AppLogger.d(
        'FoodRepository',
        'Goals loaded: ${goals.targetCalories} kcal / ${goals.targetProtein}g protein',
      );
      return goals;
    } catch (e, st) {
      AppLogger.d(
        'FoodRepository',
        'getDailyGoals Firestore read failed',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Updates the user's daily goals.
  Future<void> setDailyGoals(DailyGoals goals) async {
    if (_uid == null) {
      AppLogger.d(
        'FoodRepository',
        'setDailyGoals failed: no authenticated user',
      );
      throw Exception('User not logged in');
    }

    AppLogger.d(
      'FoodRepository',
      'Writing daily goals for uid=$_uid: ${goals.targetCalories} kcal / ${goals.targetProtein}g protein',
    );
    try {
      await _firestore
          .collection('users')
          .doc(_uid)
          .collection('goals')
          .doc('daily_food')
          .set(goals.toJson(), SetOptions(merge: true));
      AppLogger.d('FoodRepository', 'Daily goals written successfully');
    } catch (e, st) {
      AppLogger.d(
        'FoodRepository',
        'setDailyGoals Firestore write failed',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Deletes a specific food entry by its document ID.
  Future<void> deleteFoodEntry(String entryId) async {
    if (_uid == null) {
      AppLogger.d(
        'FoodRepository',
        'deleteFoodEntry failed: no authenticated user',
      );
      throw Exception('User not logged in');
    }

    AppLogger.d(
      'FoodRepository',
      'Deleting food entry id=$entryId for uid=$_uid',
    );
    try {
      await _firestore
          .collection('users')
          .doc(_uid)
          .collection('food_entries')
          .doc(entryId)
          .delete();
      AppLogger.d('FoodRepository', 'Food entry deleted successfully');
    } catch (e, st) {
      AppLogger.d(
        'FoodRepository',
        'deleteFoodEntry Firestore delete failed',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  Future<FoodEntry> autoFillFoodEntry(FoodEntry entry) async {
    final String apiUrl;
    final String apiKey;
    try {
      apiUrl = dotenv.get('AUTOFILLURL');
      apiKey = dotenv.get('AUTOFILLKEY');
    } catch (_) {
      throw Exception('Autofill is not configured. Missing .env keys.');
    }

    try {
      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {'Content-Type': 'application/json', 'x-api-key': apiKey},
            body: jsonEncode({
              ...entry.toJson(),
              'timestamp': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return FoodEntry.fromJson(json, entry.id);
      } else {
        AppLogger.d(
          'FoodRepository',
          'Autofill API error: status=${response.statusCode}',
        );
        throw Exception('Autofill failed (server error ${response.statusCode}).');
      }
    } on TimeoutException {
      throw Exception('Autofill timed out. Please try again.');
    }
  }

  String _catalogKey(String name) {
    return name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}
