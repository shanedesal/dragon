// ------------------------------------------------------------------
// File: food_viewmodel.dart
// Feature: Food
// Description: Manages state for the food tab and interacts with FoodRepository.
// ------------------------------------------------------------------
import 'package:flutter/foundation.dart';
import '../../../shared/utils/app_logger.dart';
import '../models/food_entry.dart';
import '../models/daily_goals.dart';
import '../repositories/food_repository.dart';

class FoodViewModel extends ChangeNotifier {
  final FoodRepository _repository = FoodRepository();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<FoodEntry> _dailyEntries = [];
  List<FoodEntry> get dailyEntries => _dailyEntries;

  DailyGoals _dailyGoals = DailyGoals(targetCalories: 2000, targetProtein: 100);
  DailyGoals get dailyGoals => _dailyGoals;

    int get totalCalories =>
      _dailyEntries.fold(0, (sum, entry) => sum + entry.totalCalories);
    int get totalProtein =>
      _dailyEntries.fold(0, (sum, entry) => sum + entry.totalProtein);
    int get totalCarbs =>
      _dailyEntries.fold(0, (sum, entry) => sum + entry.totalCarbs);
    int get totalFat =>
      _dailyEntries.fold(0, (sum, entry) => sum + entry.totalFat);

  FoodViewModel() {
    fetchFoodData();
  }

  Future<void> fetchFoodData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      AppLogger.d('FoodViewModel', 'Fetching food data...');
      _dailyGoals = await _repository.getDailyGoals();
      _dailyEntries = await _repository.getDailyFoodEntries();
      AppLogger.d('FoodViewModel', 'Fetched ${_dailyEntries.length} entries for today.');
    } catch (e, stack) {
      _errorMessage = 'Failed to load food data: $e';
      AppLogger.d('FoodViewModel', _errorMessage!, error: e, stackTrace: stack);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addFoodEntry(
    String name,
    int quantity,
    String unit,
    int caloriesPerUnit,
    int proteinPerUnit,
    int carbsPerUnit,
    int fatPerUnit,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final totalCalories = quantity * caloriesPerUnit;
      final totalProtein = quantity * proteinPerUnit;
      final totalCarbs = quantity * carbsPerUnit;
      final totalFat = quantity * fatPerUnit;
      AppLogger.d(
        'FoodViewModel',
        'Adding food entry: $name qty=$quantity unit=$unit '
            'kcal=$totalCalories p=$totalProtein c=$totalCarbs f=$totalFat',
      );
      final entry = FoodEntry(
        id: '', // Firestore generates this
        name: name,
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
        timestamp: DateTime.now(),
      );
      
      await _repository.addFoodEntry(entry);
      // Refresh list after adding
      _dailyEntries = await _repository.getDailyFoodEntries();
      AppLogger.d('FoodViewModel', 'Food entry added successfully.');
    } catch (e, stack) {
      _errorMessage = 'Failed to add food entry: $e';
      AppLogger.d('FoodViewModel', _errorMessage!, error: e, stackTrace: stack);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateDailyGoals(int targetCalories, int targetProtein) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      AppLogger.d('FoodViewModel', 'Updating daily goals...');
      final newGoals = DailyGoals(targetCalories: targetCalories, targetProtein: targetProtein);
      await _repository.setDailyGoals(newGoals);
      _dailyGoals = newGoals;
      AppLogger.d('FoodViewModel', 'Daily goals updated successfully.');
    } catch (e, stack) {
      _errorMessage = 'Failed to update daily goals: $e';
      AppLogger.d('FoodViewModel', _errorMessage!, error: e, stackTrace: stack);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteFoodEntry(String entryId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      AppLogger.d('FoodViewModel', 'Deleting food entry: $entryId');
      await _repository.deleteFoodEntry(entryId);
      // Remove from local list to avoid a full fetch if possible, or just re-fetch
      _dailyEntries.removeWhere((entry) => entry.id == entryId);
      AppLogger.d('FoodViewModel', 'Food entry deleted successfully.');
    } catch (e, stack) {
      _errorMessage = 'Failed to delete food entry: $e';
      AppLogger.d('FoodViewModel', _errorMessage!, error: e, stackTrace: stack);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
