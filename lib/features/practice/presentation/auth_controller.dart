import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/auth_repository.dart';
import 'guest_session_controller.dart';

class AuthController with ChangeNotifier {
  AuthController({
    AuthRepository? repository,
    GuestSessionController? guestSessionController,
  })  : _repository = repository ?? AuthRepository(),
        _guestSessionController = guestSessionController;

  final AuthRepository _repository;
  final GuestSessionController? _guestSessionController;

  bool _isLoading = false;
  String? _errorMessage;

  Stream<User?> get authStateChanges => _repository.authStateChanges;
  User? get currentUser => _repository.currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    final result = await _runAuthAction(
      () => _repository.signIn(email: email, password: password),
    );
    if (result) {
      await _guestSessionController?.exitGuestMode();
    }
    return result;
  }

  Future<bool> register({
    required String email,
    required String password,
  }) async {
    final result = await _runAuthAction(
      () => _repository.register(email: email, password: password),
    );
    if (result) {
      await _guestSessionController?.exitGuestMode();
    }
    return result;
  }

  Future<void> signOut() async {
    await _guestSessionController?.exitGuestMode();
    await _repository.signOut();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> _runAuthAction(Future<Object> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on FirebaseAuthException catch (error) {
      _errorMessage = _friendlyAuthMessage(error);
      return false;
    } catch (error) {
      _errorMessage = 'Authentication failed. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _friendlyAuthMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }
}
