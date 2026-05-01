import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dragon/features/home/models/day_steps.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages daily step counting, Firebase sync, goal storage, and history.
///
/// How it works:
/// 1. On first use, asks for motion/activity permission.
/// 2. Listens to the phone's hardware step counter sensor via [Pedometer].
/// 3. Stores a "baseline" (the sensor reading at the start of each day) in
///    SharedPreferences so we can compute "steps today = current - baseline".
/// 4. Every 30 seconds, saves today's steps to Firestore.
/// 5. Loads full step history from Firestore on demand.
class WalkViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── State ────────────────────────────────────────────────────────────────

  int _todaySteps = 0;
  int get todaySteps => _todaySteps;

  int _stepGoal = 10000;
  int get stepGoal => _stepGoal;

  /// 'walking', 'stopped', or 'unknown'
  String _status = 'stopped';
  String get status => _status;

  bool _hasPermission = false;
  bool get hasPermission => _hasPermission;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// True when running in a web browser — step tracking is not available.
  bool get isWeb => kIsWeb;

  List<DaySteps> _history = [];
  List<DaySteps> get history => _history;

  // ── Internals ────────────────────────────────────────────────────────────

  int _baseline = 0;
  String _baselineDate = '';
  SharedPreferences? _prefs;

  StreamSubscription<StepCount>? _stepCountSub;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusSub;
  Timer? _saveTimer;

  /// Whether tracking has been fully started (prevents double-init when the
  /// user navigates away and back to the Walk tab).
  bool _trackingStarted = false;

  // ── Public API ───────────────────────────────────────────────────────────

  /// Called by [WalkTab] the first time the tab mounts.
  /// Loads saved preferences, requests permission, and starts the sensor.
  Future<void> initTracking() async {
    if (_trackingStarted) return;
    _trackingStarted = true;

    _prefs = await SharedPreferences.getInstance();
    _stepGoal = _prefs!.getInt('step_goal') ?? 10000;
    _baseline = _prefs!.getInt('step_baseline') ?? 0;
    _baselineDate = _prefs!.getString('step_baseline_date') ?? '';

    if (!kIsWeb) {
      await _requestPermission();
      if (_hasPermission) {
        _startPedometer();
      }
      _startSaveTimer();
    }

    await _loadHistory();

    _isInitialized = true;
    notifyListeners();
  }

  /// Updates the daily step goal and persists it locally and to Firebase.
  Future<void> setGoal(int goal) async {
    _stepGoal = goal;
    await _prefs?.setInt('step_goal', goal);
    await _saveToFirestore();
    notifyListeners();
  }

  /// Re-fetches history from Firestore (called on pull-to-refresh).
  Future<void> refreshHistory() async {
    await _loadHistory();
    notifyListeners();
  }

  // ── Private helpers ──────────────────────────────────────────────────────

  Future<void> _requestPermission() async {
    final result = await Permission.activityRecognition.request();
    _hasPermission = result.isGranted;
  }

  void _startPedometer() {
    _stepCountSub = Pedometer.stepCountStream.listen(
      _onStepCount,
      onError: _onStepCountError,
      cancelOnError: false,
    );

    _pedestrianStatusSub = Pedometer.pedestrianStatusStream.listen(
      _onPedestrianStatus,
      onError: (_) {},
      cancelOnError: false,
    );
  }

  Future<void> _onStepCount(StepCount event) async {
    final today = _todayString();

    // If it's a new day (or the first time ever), reset the baseline so that
    // _todaySteps counts from 0 again.
    if (_baselineDate != today) {
      _baseline = event.steps;
      _baselineDate = today;
      await _prefs?.setInt('step_baseline', _baseline);
      await _prefs?.setString('step_baseline_date', today);
    }

    // Guard against negative values (e.g. device was rebooted mid-day).
    final computed = event.steps - _baseline;
    _todaySteps = computed < 0 ? event.steps : computed;
    notifyListeners();
  }

  void _onStepCountError(Object error) {
    // Happens on emulators (no hardware sensor). Silently ignored.
    debugPrint('WalkViewModel: step count error — $error');
  }

  void _onPedestrianStatus(PedestrianStatus event) {
    _status = event.status;
    notifyListeners();
  }

  void _startSaveTimer() {
    _saveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _saveToFirestore();
    });
  }

  Future<void> _saveToFirestore() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('steps')
        .doc(_todayString())
        .set({
      'steps': _todaySteps,
      'goal': _stepGoal,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _loadHistory() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Document IDs are YYYY-MM-DD — descending alphabetical = newest first.
      final snap = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('steps')
          .orderBy(FieldPath.documentId, descending: true)
          .get();

      _history = snap.docs.map((doc) {
        final data = doc.data();
        return DaySteps(
          date: doc.id,
          steps: (data['steps'] as num?)?.toInt() ?? 0,
          goal: (data['goal'] as num?)?.toInt() ?? _stepGoal,
        );
      }).toList();
    } catch (e) {
      debugPrint('WalkViewModel: failed to load history — $e');
    }
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _stepCountSub?.cancel();
    _pedestrianStatusSub?.cancel();
    _saveTimer?.cancel();
    super.dispose();
  }
}
