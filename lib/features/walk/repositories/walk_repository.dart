// ------------------------------------------------------------------
// File: walk_repository.dart
// Feature: Walk
// Description: Centralizes all Firestore reads and writes for step
//              tracking — today's steps, step history, and the user's
//              step goal. The ViewModel calls this; it never touches
//              FirebaseFirestore directly.
// ------------------------------------------------------------------

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../shared/utils/app_logger.dart';
import '../models/day_steps.dart';
import '../models/step_goal.dart';

class WalkRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // ── Today's steps ─────────────────────────────────────────────────────────

  /// Loads today's step count from Firestore.
  /// Returns 0 if the document does not exist yet.
  Future<int> loadTodaySteps(String dateKey) async {
    final uid = _uid;
    if (uid == null) return 0;

    AppLogger.d(
      'WalkRepository',
      'Loading today path=users/$uid/steps/$dateKey',
    );

    try {
      final snap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('steps')
          .doc(dateKey)
          .get();
      final steps = (snap.data()?['steps'] as num?)?.toInt() ?? 0;
      AppLogger.d('WalkRepository', 'Today loaded: steps=$steps date=$dateKey');
      return steps;
    } catch (e, st) {
      AppLogger.d('WalkRepository', 'Today load failed', error: e, stackTrace: st);
      return 0;
    }
  }

  /// Saves today's step count (and goal) to Firestore.
  Future<void> saveTodaySteps({
    required String dateKey,
    required int steps,
    required int goal,
  }) async {
    final uid = _uid;
    if (uid == null) {
      AppLogger.d('WalkRepository', 'Skip save: no authenticated user');
      return;
    }

    AppLogger.d(
      'WalkRepository',
      'Saving steps=$steps goal=$goal path=users/$uid/steps/$dateKey',
    );

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('steps')
          .doc(dateKey)
          .set({
            'steps': steps,
            'goal': goal,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      AppLogger.d('WalkRepository', 'Save complete');
    } catch (e, st) {
      AppLogger.d('WalkRepository', 'Save failed', error: e, stackTrace: st);
    }
  }

  // ── History ───────────────────────────────────────────────────────────────

  /// Fetches all historical daily step entries, newest first.
  Future<List<DaySteps>> loadHistory(int fallbackGoal) async {
    final uid = _uid;
    if (uid == null) {
      AppLogger.d('WalkRepository', 'Skip load history: no authenticated user');
      return [];
    }

    AppLogger.d('WalkRepository', 'Loading history path=users/$uid/steps');

    try {
      // Document IDs are YYYY-MM-DD — descending alphabetical = newest first.
      final snap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('steps')
          .orderBy(FieldPath.documentId, descending: true)
          .get();

      final history = snap.docs.map((doc) {
        final data = doc.data();
        return DaySteps(
          date: doc.id,
          steps: (data['steps'] as num?)?.toInt() ?? 0,
          goal: (data['goal'] as num?)?.toInt() ?? fallbackGoal,
        );
      }).toList();

      AppLogger.d('WalkRepository', 'History loaded: count=${history.length}');
      return history;
    } catch (e, st) {
      AppLogger.d('WalkRepository', 'History load failed', error: e, stackTrace: st);
      return [];
    }
  }

  // ── Goal ──────────────────────────────────────────────────────────────────

  /// Loads the user's step goal from Firestore.
  /// Returns null if the document does not exist or the value is absent.
  Future<int?> loadGoalFromFirestore() async {
    final uid = _uid;
    if (uid == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final remoteGoal = (doc.data()?['stepGoal'] as num?)?.toInt();
      AppLogger.d('WalkRepository', 'Goal loaded from Firestore: $remoteGoal');
      return remoteGoal;
    } catch (e, st) {
      AppLogger.d('WalkRepository', 'Goal load failed', error: e, stackTrace: st);
      return null;
    }
  }

  /// Persists the user's step goal to Firestore.
  Future<void> saveGoal(StepGoal goal) async {
    final uid = _uid;
    if (uid == null) return;

    try {
      await _firestore.collection('users').doc(uid).set(
        {...goal.toJson(), 'goalUpdatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
      AppLogger.d('WalkRepository', 'Goal saved: ${goal.targetSteps}');
    } catch (e, st) {
      AppLogger.d('WalkRepository', 'Goal save failed', error: e, stackTrace: st);
    }
  }
}
