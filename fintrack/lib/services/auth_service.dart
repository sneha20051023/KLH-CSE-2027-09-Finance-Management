import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

/// Represents a simple authenticated user structure across both modes.
class AuthUserInfo {
  final String uid;
  final String email;
  final String? displayName;

  AuthUserInfo({
    required this.uid,
    required this.email,
    this.displayName,
  });
}

/// AuthService handles user authentication for the FINTRACK app.
///
/// Operates in two modes:
/// - **Firebase mode**: Wraps FirebaseAuth for real authentication.
/// - **Demo mode**: Simulates auth with an in-memory mock user.
class AuthService {
  final bool isDemoMode;
  FirebaseAuth? _firebaseAuth;

  bool _isDemoLoggedIn = false;
  final StreamController<AuthUserInfo?> _demoAuthController =
      StreamController<AuthUserInfo?>.broadcast();

  static final AuthUserInfo _demoUser = AuthUserInfo(
    uid: 'demo_user_001',
    email: 'demo@fintrack.app',
    displayName: 'Demo User',
  );

  AuthService({this.isDemoMode = true}) {
    if (!isDemoMode) {
      try {
        _firebaseAuth = FirebaseAuth.instance;
      } catch (_) {
        // Fallback to demo mode if Firebase Auth cannot be initialized
      }
    }
  }

  /// Stream that emits auth state changes.
  Stream<AuthUserInfo?> get authStateChanges {
    if (isDemoMode || _firebaseAuth == null) {
      return _demoAuthController.stream;
    }

    return _firebaseAuth!.authStateChanges().map((user) {
      if (user == null) return null;
      return AuthUserInfo(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
      );
    });
  }

  /// Creates a new user account with [email], [password], and [fullName].
  Future<AuthUserInfo> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    if (email.trim().isEmpty) throw Exception('Email cannot be empty');
    if (password.trim().isEmpty) throw Exception('Password cannot be empty');
    if (fullName.trim().isEmpty) throw Exception('Full name cannot be empty');
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters');
    }

    if (isDemoMode || _firebaseAuth == null) {
      await Future.delayed(const Duration(milliseconds: 400));
      _isDemoLoggedIn = true;
      final user = AuthUserInfo(
        uid: 'user_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        displayName: fullName,
      );
      _demoAuthController.add(user);
      return user;
    }

    try {
      final credential = await _firebaseAuth!.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user?.updateDisplayName(fullName);
      final user = credential.user!;
      return AuthUserInfo(
        uid: user.uid,
        email: user.email ?? email,
        displayName: fullName,
      );
    } catch (e) {
      throw _mapFirebaseAuthError(e);
    }
  }

  /// Signs in an existing user with [email] and [password].
  Future<AuthUserInfo> signIn({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty) throw Exception('Email cannot be empty');
    if (password.trim().isEmpty) throw Exception('Password cannot be empty');

    if (isDemoMode || _firebaseAuth == null) {
      await Future.delayed(const Duration(milliseconds: 400));
      _isDemoLoggedIn = true;
      _demoAuthController.add(_demoUser);
      return _demoUser;
    }

    try {
      final credential = await _firebaseAuth!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user!;
      return AuthUserInfo(
        uid: user.uid,
        email: user.email ?? email,
        displayName: user.displayName,
      );
    } catch (e) {
      throw _mapFirebaseAuthError(e);
    }
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    if (isDemoMode || _firebaseAuth == null) {
      await Future.delayed(const Duration(milliseconds: 200));
      _isDemoLoggedIn = false;
      _demoAuthController.add(null);
      return;
    }

    await _firebaseAuth!.signOut();
  }

  /// Sends a password-reset email to [email].
  Future<void> resetPassword(String email) async {
    if (email.trim().isEmpty) throw Exception('Email cannot be empty');

    if (isDemoMode || _firebaseAuth == null) {
      await Future.delayed(const Duration(milliseconds: 300));
      return;
    }

    try {
      await _firebaseAuth!.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw _mapFirebaseAuthError(e);
    }
  }

  /// Updates the user's display name and/or photo URL.
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    if (isDemoMode || _firebaseAuth == null) {
      return;
    }

    final user = _firebaseAuth!.currentUser;
    if (user != null) {
      if (displayName != null) await user.updateDisplayName(displayName);
      if (photoURL != null) await user.updatePhotoURL(photoURL);
    }
  }

  /// Changes the user's password.
  Future<void> changePassword(String newPassword) async {
    if (newPassword.length < 6) {
      throw Exception('Password must be at least 6 characters');
    }

    if (isDemoMode || _firebaseAuth == null) {
      await Future.delayed(const Duration(milliseconds: 300));
      return;
    }

    final user = _firebaseAuth!.currentUser;
    if (user != null) {
      await user.updatePassword(newPassword);
    }
  }

  Exception _mapFirebaseAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return Exception('No user found with this email address.');
        case 'wrong-password':
        case 'invalid-credential':
          return Exception('Incorrect password or credentials.');
        case 'email-already-in-use':
          return Exception('An account already exists with this email.');
        case 'invalid-email':
          return Exception('The email address is invalid.');
        case 'weak-password':
          return Exception('The password is too weak (minimum 6 characters).');
        case 'user-disabled':
          return Exception('This user account has been disabled.');
        case 'too-many-requests':
          return Exception('Too many attempts. Please try again later.');
        case 'network-request-failed':
          return Exception('Network error. Please check your connection.');
        default:
          return Exception(error.message ?? 'Authentication failed.');
      }
    }
    return Exception(error.toString());
  }

  void dispose() {
    _demoAuthController.close();
  }
}
