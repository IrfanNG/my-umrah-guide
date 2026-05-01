import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/user_profile.dart';

class ProfileRepository {
  ProfileRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _profileRef(String uid) {
    return _firestore.collection('users').doc(uid);
  }

  Stream<UserProfile?> watchProfile(String uid) {
    return _profileRef(uid).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return UserProfile.fromFirestore(snapshot);
    });
  }

  Future<UserProfile?> getProfile(String uid) async {
    final snapshot = await _profileRef(uid).get();
    if (!snapshot.exists) return null;
    return UserProfile.fromFirestore(snapshot);
  }

  Future<void> saveProfile(UserProfile profile) {
    return _profileRef(profile.uid).set(
      profile.toFirestore(includeCreatedAt: profile.createdAt == null),
      SetOptions(merge: true),
    );
  }
}
