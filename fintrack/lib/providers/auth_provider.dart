import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

/// Manages authentication state for the FINTRACK app.
class AuthProvider extends ChangeNotifier {
  late final AuthService _authService;
  DatabaseService? _dbService;

  UserModel? _user;
  bool _isLoading = false;
  bool _isDemoMode = false;
  String? _error;

  StreamSubscription? _authSubscription;

  // ── Getters ──────────────────────────────────────────────────────────
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isDemoMode => _isDemoMode;
  bool get isAuthenticated => _user != null || _isDemoMode;
  String? get error => _error;
  DatabaseService? get dbService => _dbService;

  AuthProvider() {
    _authService = AuthService(isDemoMode: true);
    _listenToAuthChanges();
    signInDemo();
  }

  void _listenToAuthChanges() {
    _authSubscription = _authService.authStateChanges.listen(
      (authUserInfo) async {
        if (authUserInfo != null) {
          _dbService = DatabaseService(
            userId: authUserInfo.uid,
            isDemoMode: _isDemoMode,
          );
          await _loadUserProfile(authUserInfo.uid, authUserInfo.email, authUserInfo.displayName);
        } else {
          if (!_isDemoMode) {
            _user = null;
            _dbService = null;
          }
        }
        notifyListeners();
      },
      onError: (error) {
        _error = 'Auth state error: $error';
        notifyListeners();
      },
    );
  }

  Future<void> _loadUserProfile(String uid, String email, String? displayName) async {
    try {
      final db = _dbService ?? DatabaseService(userId: uid, isDemoMode: _isDemoMode);
      final profile = await db.getUserProfile();
      if (profile != null) {
        _user = profile;
      } else {
        // Create initial profile if absent
        final newProfile = UserModel(
          uid: uid,
          fullName: displayName ?? 'User',
          email: email,
          createdAt: DateTime.now(),
        );
        await db.createUserProfile(newProfile);
        _user = newProfile;
      }
    } catch (e) {
      _user = UserModel(
        uid: uid,
        fullName: displayName ?? 'FinTrack User',
        email: email,
        createdAt: DateTime.now(),
      );
    }
  }

  // ── Sign Up ──────────────────────────────────────────────────────────
  Future<bool> signUp(String email, String password, String fullName) async {
    try {
      _setLoading(true);
      clearError();

      final authUser = await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );

      _dbService = DatabaseService(userId: authUser.uid, isDemoMode: _isDemoMode);

      final newUser = UserModel(
        uid: authUser.uid,
        email: email,
        fullName: fullName,
        createdAt: DateTime.now(),
      );

      await _dbService!.createUserProfile(newUser);
      _user = newUser;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Sign In ──────────────────────────────────────────────────────────
  Future<bool> signIn(String email, String password) async {
    try {
      _setLoading(true);
      clearError();

      final authUser = await _authService.signIn(
        email: email,
        password: password,
      );

      _dbService = DatabaseService(userId: authUser.uid, isDemoMode: _isDemoMode);
      await _loadUserProfile(authUser.uid, authUser.email, authUser.displayName);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Demo Mode ────────────────────────────────────────────────────────
  Future<bool> signInDemo() async {
    try {
      _setLoading(true);
      clearError();

      _isDemoMode = true;
      _dbService = DatabaseService(userId: 'demo_user_001', isDemoMode: true);

      _user = UserModel(
        uid: 'demo_user_001',
        email: 'harini@fintrack.app',
        fullName: 'Harini',
        phoneNumber: '+91 98765 43210',
        currencySymbol: '₹',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      );

      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to start demo mode: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Sign Out ─────────────────────────────────────────────────────────
  Future<void> signOut() async {
    try {
      _setLoading(true);
      clearError();

      if (_isDemoMode) {
        _isDemoMode = false;
      }
      await _authService.signOut();

      _user = null;
      _dbService = null;
      notifyListeners();
    } catch (e) {
      _error = 'Sign-out failed: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // ── Password Reset ──────────────────────────────────────────────────
  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      clearError();
      await _authService.resetPassword(email);
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Change Password ──────────────────────────────────────────────────
  Future<bool> changePassword(String newPassword) async {
    try {
      _setLoading(true);
      clearError();
      await _authService.changePassword(newPassword);
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Update Profile ──────────────────────────────────────────────────
  Future<bool> updateProfile({
    required String fullName,
    String? phoneNumber,
    String? currencySymbol,
  }) async {
    if (_user == null) return false;
    try {
      _setLoading(true);
      final updated = _user!.copyWith(
        fullName: fullName,
        phoneNumber: phoneNumber,
        currencySymbol: currencySymbol,
      );

      await _dbService?.updateUserProfile(updated.toMap());
      _user = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update profile: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
