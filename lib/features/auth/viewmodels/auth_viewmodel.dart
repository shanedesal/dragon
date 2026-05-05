import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dragon/shared/utils/app_logger.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel() {
    _authSub = _auth.authStateChanges().listen(_handleAuthChange);
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  String? _errorMessage;

  SharedPreferences? _prefs;
  Timer? _sessionTimer;
  StreamSubscription<User?>? _authSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _lockSub;
  String? _deviceId;
  bool _isSigningOut = false;
  bool _handlingLockLoss = false;
  bool _isAuthActionInProgress = false;

  static const Duration _sessionTtl = Duration(seconds: 60);
  static const Duration _sessionHeartbeat = Duration(seconds: 30);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _auth.currentUser;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _isAuthActionInProgress = true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await _claimSessionLock(force: false);
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseError(e.code);
    } on _SessionLockException catch (e) {
      AppLogger.d(
        'AuthLock',
        'Login blocked: active session exists (device=${e.deviceId ?? 'n/a'})',
      );
      _errorMessage = 'This account is already active on another device.';
      await _auth.signOut();
    } catch (e, st) {
      AppLogger.d('Auth', 'Login failed', error: e, stackTrace: st);
      _errorMessage = 'Something went wrong. Please try again.';
    } finally {
      _isLoading = false;
      _isAuthActionInProgress = false;
      notifyListeners();
    }
  }

  Future<void> register(String email, String password) async {
    _isAuthActionInProgress = true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await _claimSessionLock(force: false);
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseError(e.code);
    } on _SessionLockException catch (e) {
      AppLogger.d(
        'AuthLock',
        'Register blocked: active session exists (device=${e.deviceId ?? 'n/a'})',
      );
      _errorMessage = 'This account is already active on another device.';
      await _auth.signOut();
    } catch (e, st) {
      AppLogger.d('Auth', 'Register failed', error: e, stackTrace: st);
      _errorMessage = 'Something went wrong. Please try again.';
    } finally {
      _isLoading = false;
      _isAuthActionInProgress = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isSigningOut = true;
    _stopLockListener();
    _stopSessionHeartbeat();
    await _releaseSessionLock();
    await _auth.signOut();
    _isSigningOut = false;
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _stopLockListener();
    _stopSessionHeartbeat();
    super.dispose();
  }

  CollectionReference<Map<String, dynamic>> _sessionCollection(String uid) {
    return _firestore.collection('users').doc(uid).collection('session');
  }

  DocumentReference<Map<String, dynamic>> _sessionLockRef(String uid) {
    return _sessionCollection(uid).doc('lock');
  }

  Future<String> _ensureDeviceId() async {
    _prefs ??= await SharedPreferences.getInstance();
    final existing = _prefs!.getString('device_id');
    if (existing != null && existing.isNotEmpty) {
      _deviceId = existing;
      return existing;
    }

    final random = Random();
    final id = 'dev_${DateTime.now().millisecondsSinceEpoch}_${random.nextInt(1 << 32)}';
    await _prefs!.setString('device_id', id);
    _deviceId = id;
    return id;
  }

  Future<void> _claimSessionLock({
    bool startHeartbeat = true,
    bool force = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final deviceId = await _ensureDeviceId();
    final lockRef = _sessionLockRef(user.uid);
    final now = DateTime.now();

    Future<void> runLockTransaction() async {
      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(lockRef);
        if (snap.exists) {
          final data = snap.data();
          final existingDevice = data?['deviceId'] as String? ?? '';
          final lastSeenTs = data?['lastSeenAt'] as Timestamp?;
          final lastSeen = lastSeenTs?.toDate();
          final expired =
              lastSeen == null || now.difference(lastSeen) > _sessionTtl;
          final sameDevice = existingDevice == deviceId;

          if (!sameDevice && !expired && !force) {
            throw _SessionLockException(
              deviceId: existingDevice,
              lastSeenAt: lastSeen,
            );
          }
        }

        tx.set(
          lockRef,
          {
            'deviceId': deviceId,
            'lastSeenAt': FieldValue.serverTimestamp(),
            'claimedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      });
    }

    try {
      await runLockTransaction();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        AppLogger.d(
          'AuthLock',
          'Permission denied on lock claim, refreshing token and retrying',
        );
        await user.getIdToken(true);
        await Future<void>.delayed(const Duration(milliseconds: 200));
        await runLockTransaction();
      } else {
        rethrow;
      }
    }

    if (force) {
      AppLogger.d('AuthLock', 'Session lock forced (device=$deviceId)');
    } else {
      AppLogger.d('AuthLock', 'Session lock claimed (device=$deviceId)');
    }
    if (startHeartbeat) {
      _startSessionHeartbeat();
    }
    _startLockListener(user.uid);
  }

  void _startSessionHeartbeat() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(_sessionHeartbeat, (_) async {
      try {
        await _claimSessionLock(startHeartbeat: false, force: false);
      } on _SessionLockException catch (e) {
        await _handleLockLost(
          'Session lock lost during heartbeat (device=${e.deviceId ?? 'n/a'})',
        );
      } catch (e, st) {
        AppLogger.d('AuthLock', 'Heartbeat failed', error: e, stackTrace: st);
      }
    });
  }

  void _startLockListener(String uid) {
    _lockSub?.cancel();
    _lockSub = _sessionLockRef(uid).snapshots().listen((snapshot) async {
      if (_isSigningOut || _isAuthActionInProgress) return;
      if (!snapshot.exists) {
        AppLogger.d('AuthLock', 'Session lock missing; waiting for heartbeat');
        return;
      }

      final data = snapshot.data();
      final deviceId = data?['deviceId'] as String? ?? '';
      final current = _deviceId ?? await _ensureDeviceId();
      if (deviceId.isNotEmpty && deviceId != current) {
        await _handleLockLost('Session lock taken by another device');
      }
    });
  }

  void _stopLockListener() {
    _lockSub?.cancel();
    _lockSub = null;
  }

  void _stopSessionHeartbeat() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
  }

  Future<void> _releaseSessionLock() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final deviceId = await _ensureDeviceId();
    final lockRef = _sessionLockRef(user.uid);

    try {
      final snap = await lockRef.get();
      final data = snap.data();
      final existingDevice = data?['deviceId'] as String? ?? '';
      if (existingDevice == deviceId) {
        await lockRef.delete();
        AppLogger.d('AuthLock', 'Session lock released (device=$deviceId)');
      }
    } catch (e, st) {
      AppLogger.d('AuthLock', 'Release failed', error: e, stackTrace: st);
    }
  }

  Future<void> _handleAuthChange(User? user) async {
    if (_isAuthActionInProgress || _isSigningOut) return;
    if (user == null) return;
    try {
      await _claimSessionLock(force: false);
    } on _SessionLockException catch (e) {
      await _handleLockLost(
        'Session restore blocked (device=${e.deviceId ?? 'n/a'})',
      );
    }
  }

  Future<void> _handleLockLost(String reason) async {
    if (_handlingLockLoss) return;
    _handlingLockLoss = true;
    AppLogger.d('AuthLock', reason);
    _errorMessage = 'This account is already active on another device.';
    notifyListeners();
    await logout();
    _handlingLockLoss = false;
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'operation-not-allowed':
        return 'Email/password sign-up is not enabled.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}

class _SessionLockException implements Exception {
  const _SessionLockException({this.deviceId, this.lastSeenAt});

  final String? deviceId;
  final DateTime? lastSeenAt;
}
