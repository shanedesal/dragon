// ------------------------------------------------------------------
// File: walk_viewmodel.dart
// Feature: Walk
// Description: ViewModel managing step tracking, goal persistence, and history.
// ------------------------------------------------------------------

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dragon/features/walk/models/day_steps.dart';
import 'package:dragon/features/walk/models/step_goal.dart';
import 'package:dragon/shared/utils/app_logger.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages daily step counting, Firebase sync, goal storage, and history.
///
/// How it works:
/// 1. Loads today's steps from Firestore (source of truth).
/// 2. Reads the sensor total and adds only the delta since last open.
/// 3. Saves immediately after catch-up, then every 30 seconds.
/// 4. Loads full step history from Firestore on demand.
class WalkViewModel extends ChangeNotifier with WidgetsBindingObserver {
  WalkViewModel() {
    _authSub = _auth.authStateChanges().listen(_handleAuthChange);
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── State ────────────────────────────────────────────────────────────────

  int _todaySteps = 0;
  int get todaySteps => _todaySteps;

  StepGoal _goal = const StepGoal(targetSteps: 10000);
  int get stepGoal => _goal.targetSteps;

  /// 'walking', 'stopped', or 'unknown'
  String _status = 'stopped';
  String get status => _status;
  String _lastLoadedDate = '';

  bool _hasPermission = false;
  bool get hasPermission => _hasPermission;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// True when running in a web browser — step tracking is not available.
  bool get isWeb => kIsWeb;

  List<DaySteps> _history = [];
  List<DaySteps> get history => _history;

  // ── Internals ────────────────────────────────────────────────────────────

  SharedPreferences? _prefs;

  StreamSubscription<StepCount>? _stepCountSub;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusSub;
  Timer? _saveTimer;
  StreamSubscription<User?>? _authSub;
  bool _observerAttached = false;

  DateTime? _lastStepLogAt;
  int _lastLoggedSteps = 0;

  String _activeUserId = '';
  int _lastSensorTotal = 0;
  bool _hasLastSensorTotal = false;
  bool _resetLastSensorOnNextEvent = false;
  bool _needsImmediateSave = false;

  /// Whether tracking has been fully started (prevents double-init when the
  /// user navigates away and back to the Walk tab).
  bool _trackingStarted = false;

  // ── Public API ───────────────────────────────────────────────────────────

  /// Called by [WalkTab] the first time the tab mounts.
  /// Loads saved preferences, requests permission, and starts the sensor.
  Future<void> initTracking() async {
    if (_trackingStarted) {
      AppLogger.d('Walk', 'initTracking skipped (already started)');
      return;
    }
    final user = _auth.currentUser;
    if (user == null) {
      AppLogger.d('WalkAuth', 'initTracking skipped: no user');
      return;
    }

    _trackingStarted = true;
    _activeUserId = user.uid;
    AppLogger.d('Walk', 'initTracking start (isWeb=$kIsWeb user=${user.uid})');

    await _ensurePrefs();
    await _loadUserPrefs(user.uid);
    await _loadUserGoal();
    await _loadTodayFromFirestore();
    _scheduleMidnightRollover();
    _needsImmediateSave = true;

    if (!_observerAttached) {
      WidgetsBinding.instance.addObserver(this);
      _observerAttached = true;
    }

    if (!kIsWeb) {
      await _requestPermission();
      if (_hasPermission) {
        _startPedometer();
      } else {
        AppLogger.d('Walk', 'Permission denied, pedometer not started');
      }
      _startSaveTimer();
    } else {
      AppLogger.d('Walk', 'Web detected, skipping pedometer');
    }

    await _loadHistory();

    _isInitialized = true;
    AppLogger.d('Walk', 'initTracking done (history=${_history.length})');
    notifyListeners();
  }

  /// Updates the daily step goal and persists it locally and to Firebase.
  Future<void> setGoal(int goal) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final previous = _goal.targetSteps;
    _goal = StepGoal(targetSteps: goal);
    await _prefs?.setInt(_userKey(user.uid, 'step_goal'), goal);
    await _saveGoalToFirestore();
    await _saveToFirestore();
    AppLogger.d('WalkGoal', 'Goal updated: $previous -> $goal');
    notifyListeners();
  }

  /// Re-fetches history from Firestore (called on pull-to-refresh).
  Future<void> refreshHistory() async {
    AppLogger.d('WalkFirestore', 'Manual history refresh requested');
    await _loadTodayFromFirestore();
    await _loadHistory();
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_auth.currentUser == null || !_trackingStarted) return;
      AppLogger.d('Walk', 'App resumed, refreshing today');
      _needsImmediateSave = true;
      () async {
        await _loadUserGoal();
        await _loadTodayFromFirestore();
        _scheduleMidnightRollover();
        notifyListeners();
      }();
    }
  }

  // ── Private helpers ──────────────────────────────────────────────────────

  Future<void> _ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  String _userKey(String uid, String suffix) => 'walk_${uid}_$suffix';

  Future<void> _loadUserPrefs(String uid) async {
    final lastActive = _prefs?.getString('walk_last_active_user') ?? '';
    if (lastActive != uid) {
      _resetLastSensorOnNextEvent = true;
      await _prefs?.setString('walk_last_active_user', uid);
      AppLogger.d('Walk', 'User switch detected, resetting sensor baseline');
    }

    final today = _todayString();
    final lastSensorDate =
        _prefs?.getString(_userKey(uid, 'last_sensor_date')) ?? '';
    final dayChanged = lastSensorDate.isNotEmpty && lastSensorDate != today;
    if (dayChanged) {
      _resetLastSensorOnNextEvent = true;
      AppLogger.d(
        'Walk',
        'Day changed, resetting sensor baseline: '
            'last=$lastSensorDate today=$today',
      );
    }

    final shouldReset = _resetLastSensorOnNextEvent || dayChanged;
    final lastTotal = _prefs?.getInt(_userKey(uid, 'last_sensor_total'));
    if (lastTotal != null && !shouldReset) {
      _lastSensorTotal = lastTotal;
      _hasLastSensorTotal = true;
    } else {
      _lastSensorTotal = 0;
      _hasLastSensorTotal = false;
    }
  }

  Future<void> _persistLastSensorTotal() async {
    if (_activeUserId.isEmpty) return;
    await _prefs?.setInt(
      _userKey(_activeUserId, 'last_sensor_total'),
      _lastSensorTotal,
    );
    await _prefs?.setString(
      _userKey(_activeUserId, 'last_sensor_date'),
      _todayString(),
    );
  }

  Future<void> _loadUserGoal() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final data = doc.data();
      final remoteGoal = (data?['stepGoal'] as num?)?.toInt();
      if (remoteGoal != null && remoteGoal > 0) {
        _goal = StepGoal(targetSteps: remoteGoal);
        await _prefs?.setInt(
          _userKey(user.uid, 'step_goal'),
          _goal.targetSteps,
        );
        return;
      }
    } catch (e, st) {
      AppLogger.d('WalkGoal', 'Goal load failed', error: e, stackTrace: st);
    }

    _goal = StepGoal(
      targetSteps: _prefs?.getInt(_userKey(user.uid, 'step_goal')) ?? 10000,
    );
    await _saveGoalToFirestore();
  }

  Future<void> _saveGoalToFirestore() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).set({
        ..._goal.toJson(),
        'goalUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e, st) {
      AppLogger.d('WalkGoal', 'Goal save failed', error: e, stackTrace: st);
    }
  }

  Future<void> _requestPermission() async {
    AppLogger.d('WalkPermission', 'Requesting activity recognition');
    final result = await Permission.activityRecognition.request();
    _hasPermission = result.isGranted;
    AppLogger.d(
      'WalkPermission',
      'Result: granted=$_hasPermission status=${result.name}',
    );
  }

  void _startPedometer() {
    AppLogger.d('WalkSensor', 'Starting pedometer streams');
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
    if (_activeUserId.isEmpty) return;

    if (_resetLastSensorOnNextEvent || !_hasLastSensorTotal) {
      final reason = _resetLastSensorOnNextEvent ? 'user switch' : 'first run';
      AppLogger.d(
        'WalkSteps',
        'Sensor baseline set ($reason): total=${event.steps}',
      );
      _resetLastSensorOnNextEvent = false;
      _lastSensorTotal = event.steps;
      _hasLastSensorTotal = true;
      await _persistLastSensorTotal();
      _needsImmediateSave = false;
      _logStepEvent(event, 0);
      notifyListeners();
      return;
    }

    final today = _todayString();
    if (_lastLoadedDate.isNotEmpty && today != _lastLoadedDate) {
      AppLogger.d(
        'Walk',
        'Day changed in step stream: $_lastLoadedDate -> $today',
      );
      await _loadTodayFromFirestore();
      _lastLoadedDate = today;
      _needsImmediateSave = true;
      _upsertTodayHistory();
    }

    final delta = event.steps - _lastSensorTotal;
    if (delta < 0) {
      AppLogger.d(
        'WalkSteps',
        'Sensor total decreased, resetting baseline: '
            'prev=$_lastSensorTotal new=${event.steps}',
      );
      _lastSensorTotal = event.steps;
      await _persistLastSensorTotal();
      _needsImmediateSave = false;
      _logStepEvent(event, 0);
      notifyListeners();
      return;
    }

    if (delta > 0) {
      _todaySteps += delta;
    }

    _lastSensorTotal = event.steps;
    await _persistLastSensorTotal();
    _logStepEvent(event, delta);

    if (_needsImmediateSave) {
      _needsImmediateSave = false;
      if (delta > 0) {
        await _saveToFirestore();
      }
    }

    notifyListeners();
  }

  void _onStepCountError(Object error) {
    // Happens on emulators (no hardware sensor). Silently ignored.
    AppLogger.d(
      'WalkSteps',
      'Step count error (sensor unavailable)',
      error: error,
    );
  }

  void _onPedestrianStatus(PedestrianStatus event) {
    if (_status != event.status) {
      AppLogger.d('WalkStatus', 'Status changed: $_status -> ${event.status}');
    }
    _status = event.status;
    notifyListeners();
  }

  void _startSaveTimer() {
    AppLogger.d('WalkFirestore', 'Save timer started (30s interval)');
    _saveTimer?.cancel();
    _saveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _saveToFirestore();
    });
  }

  Future<void> _saveToFirestore() async {
    final user = _auth.currentUser;
    if (user == null) {
      AppLogger.d('WalkFirestore', 'Skip save: no authenticated user');
      return;
    }

    final docId = _todayString();
    AppLogger.d(
      'WalkFirestore',
      'Saving steps=$_todaySteps goal=${_goal.targetSteps} '
          'path=users/${user.uid}/steps/$docId',
    );

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('steps')
          .doc(docId)
          .set({
            'steps': _todaySteps,
            'goal': _goal.targetSteps,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      _upsertTodayHistory();
      AppLogger.d('WalkFirestore', 'Save complete');
    } catch (e, st) {
      AppLogger.d('WalkFirestore', 'Save failed', error: e, stackTrace: st);
    }
  }

  Future<void> _loadTodayFromFirestore() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docId = _todayString();
    AppLogger.d(
      'WalkFirestore',
      'Loading today path=users/${user.uid}/steps/$docId',
    );

    try {
      final snap = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('steps')
          .doc(docId)
          .get();
      final data = snap.data();
      _todaySteps = (data?['steps'] as num?)?.toInt() ?? 0;
    } catch (e, st) {
      AppLogger.d(
        'WalkFirestore',
        'Today load failed',
        error: e,
        stackTrace: st,
      );
    }
    _lastLoadedDate = _todayString();
    AppLogger.d(
      'WalkFirestore',
      'Today loaded: steps=$_todaySteps goal=${_goal.targetSteps} date=$_lastLoadedDate',
    );
  }

  Future<void> _loadHistory() async {
    final user = _auth.currentUser;
    if (user == null) {
      AppLogger.d('WalkFirestore', 'Skip load history: no authenticated user');
      return;
    }

    AppLogger.d(
      'WalkFirestore',
      'Loading history path=users/${user.uid}/steps',
    );

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
          goal: (data['goal'] as num?)?.toInt() ?? _goal.targetSteps,
        );
      }).toList();
      AppLogger.d('WalkFirestore', 'History loaded: count=${_history.length}');
    } catch (e) {
      AppLogger.d('WalkFirestore', 'History load failed', error: e);
    }
  }

  void _logStepEvent(StepCount event, int delta) {
    if (!kDebugMode) return;
    final now = DateTime.now();
    final timeReady =
        _lastStepLogAt == null ||
        now.difference(_lastStepLogAt!).inSeconds >= 10;
    final stepDelta = (_todaySteps - _lastLoggedSteps).abs() >= 100;
    if (!timeReady && !stepDelta) return;

    _lastStepLogAt = now;
    _lastLoggedSteps = _todaySteps;
    AppLogger.d(
      'WalkSteps',
      'Step event: total=${event.steps} delta=$delta '
          'today=$_todaySteps status=$_status',
    );
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  void _handleAuthChange(User? user) {
    final uid = user?.uid ?? '';
    if (uid == _activeUserId) return;

    AppLogger.d('WalkAuth', 'Auth changed: prev=$_activeUserId new=$uid');
    _activeUserId = uid;
    _trackingStarted = false;
    _isInitialized = false;
    _needsImmediateSave = false;
    _resetLastSensorOnNextEvent = false;
    _hasLastSensorTotal = false;
    _lastSensorTotal = 0;
    _status = 'stopped';
    _history = [];
    _todaySteps = 0;
    _hasPermission = false;
    _cancelTracking();
    notifyListeners();
  }

  Timer? _midnightTimer;

  void _scheduleMidnightRollover() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final delay = nextMidnight.difference(now);
    AppLogger.d(
      'Walk',
      'Midnight rollover scheduled in ${delay.inMinutes}m ${delay.inSeconds % 60}s',
    );
    _midnightTimer = Timer(delay, () {
      AppLogger.d('Walk', 'Midnight rollover timer fired');
      _handleMidnightRollover();
    });
  }

  Future<void> _handleMidnightRollover() async {
    if (_auth.currentUser == null || !_trackingStarted) return;

    final today = _todayString();
    if (_lastLoadedDate == today) {
      AppLogger.d('Walk', 'Midnight rollover skipped: already on $today');
      _scheduleMidnightRollover();
      return;
    }

    AppLogger.d('Walk', 'Midnight rollover start: $_lastLoadedDate -> $today');
    await _loadTodayFromFirestore();
    _lastLoadedDate = today;
    _needsImmediateSave = true;
    _upsertTodayHistory();
    notifyListeners();
    _scheduleMidnightRollover();
  }

  void _cancelTracking() {
    _stepCountSub?.cancel();
    _stepCountSub = null;
    _pedestrianStatusSub?.cancel();
    _pedestrianStatusSub = null;
    _saveTimer?.cancel();
    _saveTimer = null;
    _midnightTimer?.cancel();
    _midnightTimer = null;
  }

  void _upsertTodayHistory() {
    final today = _todayString();
    final updated = DaySteps(
      date: today,
      steps: _todaySteps,
      goal: _goal.targetSteps,
    );

    final index = _history.indexWhere((day) => day.date == today);
    if (index == -1) {
      _history = [updated, ..._history];
    } else {
      final next = [..._history];
      next[index] = updated;
      _history = next;
    }
  }

  @override
  void dispose() {
    AppLogger.d('Walk', 'Dispose: cancelling streams and timer');
    _cancelTracking();
    _authSub?.cancel();
    if (_observerAttached) {
      WidgetsBinding.instance.removeObserver(this);
      _observerAttached = false;
    }
    super.dispose();
  }
}
