import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_user.dart';
import 'auth_provider.dart';

// Does the current user follow targetUserId?
final isFollowingProvider =
    StreamProvider.family<bool, String>((ref, targetUserId) {
  final auth = ref.watch(authStateProvider);
  return auth.when(
    data: (user) {
      if (user == null) return Stream.value(false);
      return FirebaseFirestore.instance
          .collection('follows')
          .doc('${user.uid}_$targetUserId')
          .snapshots()
          .map((doc) => doc.exists);
    },
    loading: () => Stream.value(false),
    error: (_, _) => Stream.value(false),
  );
});

final followersCountProvider =
    StreamProvider.family<int, String>((ref, userId) {
  return FirebaseFirestore.instance
      .collection('follows')
      .where('followingId', isEqualTo: userId)
      .snapshots()
      .map((s) => s.docs.length);
});

final followingCountProvider =
    StreamProvider.family<int, String>((ref, userId) {
  return FirebaseFirestore.instance
      .collection('follows')
      .where('followerId', isEqualTo: userId)
      .snapshots()
      .map((s) => s.docs.length);
});

// Users that the current user follows (live stream for send-to picker)
final myFollowingProvider =
    StreamProvider.family<List<AppUser>, String>((ref, userId) {
  return FirebaseFirestore.instance
      .collection('follows')
      .where('followerId', isEqualTo: userId)
      .snapshots()
      .asyncMap((snapshot) async {
    if (snapshot.docs.isEmpty) return <AppUser>[];
    final ids = snapshot.docs
        .map((d) => d.data()['followingId'] as String)
        .toList();
    final userDocs = await Future.wait(
      ids.map((id) =>
          FirebaseFirestore.instance.collection('users').doc(id).get()),
    );
    return userDocs
        .where((d) => d.exists)
        .map(AppUser.fromFirestore)
        .toList();
  });
});

class FollowService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FollowService(this._firestore, this._auth);

  Future<void> follow(String targetUserId) async {
    final uid = _auth.currentUser!.uid;
    await _firestore
        .collection('follows')
        .doc('${uid}_$targetUserId')
        .set({
      'followerId': uid,
      'followingId': targetUserId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unfollow(String targetUserId) async {
    final uid = _auth.currentUser!.uid;
    await _firestore
        .collection('follows')
        .doc('${uid}_$targetUserId')
        .delete();
  }
}

final followServiceProvider = Provider((ref) => FollowService(
      ref.watch(firestoreProvider),
      ref.watch(firebaseAuthProvider),
    ));
