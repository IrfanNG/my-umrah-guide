import 'package:flutter/material.dart';

import '../data/profile_repository.dart';
import '../domain/user_profile.dart';

class ProfileController with ChangeNotifier {
  ProfileController({ProfileRepository? repository})
      : _repository = repository ?? ProfileRepository();

  final ProfileRepository _repository;

  bool _isSaving = false;
  String? _errorMessage;

  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  Stream<UserProfile?> watchProfile(String uid) => _repository.watchProfile(uid);

  Future<UserProfile?> getProfile(String uid) => _repository.getProfile(uid);

  Future<bool> saveProfile(UserProfile profile) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.saveProfile(profile);
      return true;
    } catch (_) {
      _errorMessage = 'Unable to save profile. Please try again.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
