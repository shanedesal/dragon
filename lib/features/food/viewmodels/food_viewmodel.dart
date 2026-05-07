// ------------------------------------------------------------------
// File: food_viewmodel.dart
// Feature: Food
// Description: Manages state for the food tab and interacts with FoodRepository.
// ------------------------------------------------------------------
import 'dart:async';

import 'package:flutter/widgets.dart';
import '../../../shared/utils/app_logger.dart';
import '../models/food_entry.dart';
import '../models/daily_goals.dart';
import '../repositories/food_repository.dart';

class FoodViewModel extends ChangeNotifier with WidgetsBindingObserver {
  final FoodRepository _repository = FoodRepository();

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool _isAutoFilling = false;
  bool get isAutoFilling => _isAutoFilling;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<FoodEntry> _dailyEntries = [];
  List<FoodEntry> get dailyEntries => _dailyEntries;

  DailyGoals _dailyGoals = DailyGoals(targetCalories: 2000, targetProtein: 100);
  DailyGoals get dailyGoals => _dailyGoals;

  String _lastLoadedDate = '';
  Timer? _midnightTimer;
  bool _observerAttached = false;

  int get totalCalories =>
      _dailyEntries.fold(0, (sum, entry) => sum + entry.totalCalories);
  int get totalProtein =>
      _dailyEntries.fold(0, (sum, entry) => sum + entry.totalProtein);
  int get totalCarbs =>
      _dailyEntries.fold(0, (sum, entry) => sum + entry.totalCarbs);
  int get totalFat =>
      _dailyEntries.fold(0, (sum, entry) => sum + entry.totalFat);

  FoodViewModel() {
    WidgetsBinding.instance.addObserver(this);
    _observerAttached = true;
    AppLogger.d('Food', 'FoodViewModel created');
    fetchFoodData(reason: 'startup');
  }

  Future<void> fetchFoodData({String reason = 'manual'}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      AppLogger.d(
        'FoodViewModel',
        'Fetching food data (reason=$reason date=${_todayString()})',
      );
      _dailyGoals = await _repository.getDailyGoals();
      _dailyEntries = await _repository.getDailyFoodEntries();
      _lastLoadedDate = _todayString();
      AppLogger.d(
        'FoodViewModel',
        'Fetched ${_dailyEntries.length} entries for $_lastLoadedDate',
      );
    } catch (e, stack) {
      _errorMessage = 'Failed to load food data: $e';
      AppLogger.d('FoodViewModel', _errorMessage!, error: e, stackTrace: stack);
    } finally {
      _isLoading = false;
      _scheduleMidnightRefresh();
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
      AppLogger.d('FoodViewModel', 'Add food entry requested: $name');
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
      _lastLoadedDate = _todayString();
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
      AppLogger.d(
        'FoodViewModel',
        'Updating daily goals: $targetCalories kcal / $targetProtein g',
      );
      final newGoals = DailyGoals(
        targetCalories: targetCalories,
        targetProtein: targetProtein,
      );
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    AppLogger.d('Food', 'App resumed, refreshing food data');
    fetchFoodData(reason: 'resume');
  }

  Future<void> _refreshForMidnight() async {
    final today = _todayString();
    if (_lastLoadedDate == today) {
      AppLogger.d('Food', 'Midnight refresh skipped: already on $today');
      return;
    }

    AppLogger.d(
      'Food',
      'Midnight refresh triggered: $_lastLoadedDate -> $today',
    );
    await fetchFoodData(reason: 'midnight');
  }

  void _scheduleMidnightRefresh() {
    _midnightTimer?.cancel();

    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final delay = nextMidnight.difference(now);

    AppLogger.d(
      'Food',
      'Midnight refresh scheduled in ${delay.inMinutes}m ${delay.inSeconds % 60}s',
    );

    _midnightTimer = Timer(delay, () {
      AppLogger.d('Food', 'Midnight refresh timer fired');
      _refreshForMidnight();
    });
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    AppLogger.d('Food', 'Dispose: cancelling midnight timer and observer');
    _midnightTimer?.cancel();
    if (_observerAttached) {
      WidgetsBinding.instance.removeObserver(this);
      _observerAttached = false;
    }
    super.dispose();
  }

  Future<FoodEntry?> autoFillFoodEntry(FoodEntry entry) async {
    _isAutoFilling = true;
    _errorMessage = null;
    notifyListeners();

    try {
      AppLogger.d('FoodViewModel', 'Auto-filling food entry: ${entry.name}');
      final autoFilledEntry = await _repository.autoFillFoodEntry(entry);
      AppLogger.d('FoodViewModel', 'Auto-fill successful: ${entry.name}');
      return autoFilledEntry;
    } catch (e, stack) {
      _errorMessage = 'Failed to auto-fill food entry: $e';
      AppLogger.d('FoodViewModel', _errorMessage!, error: e, stackTrace: stack);
      return null;
    } finally {
      _isAutoFilling = false;
      notifyListeners();
    }
  }
}
