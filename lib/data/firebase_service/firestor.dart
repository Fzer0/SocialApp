import 'package:app/data/model/usermodel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class AppException implements Exception {
  final String message;
  AppException(this.message);

  @override
  String toString() => 'AppException: $message';
}

class FirebaseFirestor {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _createNotification({
    required String targetUid,
    required String notificationId,
    required String type,
    required String fromUid,
    required String fromUsername,
    required String fromProfileImage,
    String? postId,
    String? postImage,
    String? commentText,
  }) async {
    if (targetUid.isEmpty || fromUid.isEmpty) return;
    if (targetUid == fromUid) return;

    await _firebaseFirestore
        .collection('users')
        .doc(targetUid)
        .collection('notifications')
        .doc(notificationId)
        .set({
      'type': type,
      'fromUid': fromUid,
      'fromUsername': fromUsername,
      'fromProfileImage': fromProfileImage,
      'postId': postId ?? '',
      'postImage': postImage ?? '',
      'commentText': commentText ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    }, SetOptions(merge: true));
  }

  Future<void> _deleteNotification({
    required String targetUid,
    required String notificationId,
  }) async {
    await _firebaseFirestore
        .collection('users')
        .doc(targetUid)
        .collection('notifications')
        .doc(notificationId)
        .delete()
        .catchError((_) {});
  }

  Future<void> toggleLike({required String postId}) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw AppException('User not authenticated');

      final docRef = _firebaseFirestore.collection('posts').doc(postId);
      final snap = await docRef.get();

      if (!snap.exists) return;

      final data = snap.data() ?? {};
      final likes = List.from(data['likes'] ?? []);
      final postOwnerUid = (data['uid'] ?? '') as String;
      final postImage = (data['postImage'] ?? '') as String;

      final currentUser = await getUser();
      final notificationId = 'like_${postId}_$uid';

      if (likes.contains(uid)) {
        await docRef.update({
          'likes': FieldValue.arrayRemove([uid]),
        });

        if (postOwnerUid.isNotEmpty && postOwnerUid != uid) {
          await _deleteNotification(
            targetUid: postOwnerUid,
            notificationId: notificationId,
          );
        }
      } else {
        await docRef.update({
          'likes': FieldValue.arrayUnion([uid]),
        });

        if (postOwnerUid.isNotEmpty && postOwnerUid != uid) {
          await _createNotification(
            targetUid: postOwnerUid,
            notificationId: notificationId,
            type: 'like',
            fromUid: uid,
            fromUsername: currentUser.username,
            fromProfileImage: currentUser.profile,
            postId: postId,
            postImage: postImage,
          );
        }
      }
    } on FirebaseException catch (e) {
      throw AppException(e.message ?? 'Error toggling like');
    }
  }

  Future<void> followUser({required String targetUid}) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw AppException('User not authenticated');
      if (uid == targetUid) return;

      final targetRef = _firebaseFirestore.collection('users').doc(targetUid);
      final meRef = _firebaseFirestore.collection('users').doc(uid);

      final batch = _firebaseFirestore.batch();
      batch.update(targetRef, {
        'followers': FieldValue.arrayUnion([uid]),
      });
      batch.update(meRef, {
        'following': FieldValue.arrayUnion([targetUid]),
      });

      await batch.commit();

      final currentUser = await getUser();

      await _createNotification(
        targetUid: targetUid,
        notificationId: 'follow_$uid',
        type: 'follow',
        fromUid: uid,
        fromUsername: currentUser.username,
        fromProfileImage: currentUser.profile,
      );
    } on FirebaseException catch (e) {
      throw AppException(e.message ?? 'Error following user');
    }
  }

  Future<void> unfollowUser({required String targetUid}) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw AppException('User not authenticated');
      if (uid == targetUid) return;

      final targetRef = _firebaseFirestore.collection('users').doc(targetUid);
      final meRef = _firebaseFirestore.collection('users').doc(uid);

      final batch = _firebaseFirestore.batch();
      batch.update(targetRef, {
        'followers': FieldValue.arrayRemove([uid]),
      });
      batch.update(meRef, {
        'following': FieldValue.arrayRemove([targetUid]),
      });

      await batch.commit();

      await _deleteNotification(
        targetUid: targetUid,
        notificationId: 'follow_$uid',
      );
    } on FirebaseException catch (e) {
      throw AppException(e.message ?? 'Error unfollowing user');
    }
  }

  Future<bool> CreateUser({
    required String email,
    required String username,
    required String bio,
    required String profile,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw AppException('User not authenticated');

    await _firebaseFirestore.collection('users').doc(uid).set({
      'email': email,
      'username': username,
      'bio': bio,
      'profile': profile,
      'coverImage': '',
      'followers': [],
      'following': [],
    });

    return true;
  }

  Future<Usermodel> getUser() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw AppException('User not authenticated');

      final user = await _firebaseFirestore.collection('users').doc(uid).get();
      final snapuser = user.data();

      if (snapuser == null) throw AppException('User document not found');

      return Usermodel(
        email: snapuser['email'] ?? '',
        username: snapuser['username'] ?? '',
        bio: snapuser['bio'] ?? '',
        profile: snapuser['profile'] ?? '',
        coverImage: snapuser['coverImage'] ?? '',
        followers: snapuser['followers'] ?? [],
        following: snapuser['following'] ?? [],
      );
    } on FirebaseException catch (e) {
      throw AppException(e.message.toString());
    }
  }

  Future<Usermodel> getUserById(String uid) async {
    try {
      final doc = await _firebaseFirestore.collection('users').doc(uid).get();
      final data = doc.data();

      if (data == null) throw AppException('User not found');

      return Usermodel(
        email: (data['email'] ?? '') as String,
        username: (data['username'] ?? '') as String,
        bio: (data['bio'] ?? '') as String,
        profile: (data['profile'] ?? '') as String,
        coverImage: (data['coverImage'] ?? '') as String,
        followers: (data['followers'] ?? []) as List,
        following: (data['following'] ?? []) as List,
      );
    } on FirebaseException catch (e) {
      throw AppException(e.message.toString());
    }
  }

  Future<bool> CreatePost({
    required String postImage,
    required String caption,
    required String location,
  }) async {
    final postId = const Uuid().v4();

    try {
      Usermodel user;

      try {
        user = await getUser();
      } catch (_) {
        final authUser = _auth.currentUser;
        user = Usermodel(
          email: authUser?.email ?? '',
          username: authUser?.displayName ??
              (authUser?.email?.split('@').first ?? 'user'),
          bio: '',
          profile:
              'https://firebasestorage.googleapis.com/v0/b/instagram-8a227.appspot.com/o/person.png?alt=media&token=c6fcbe9d-f502-4aa1-8b4b-ec37339e78ab',
          followers: [],
          following: [], coverImage: '',
        );
      }

      final docRef = _firebaseFirestore.collection('posts').doc(postId);

      await docRef.set({
        'postImage': postImage,
        'username': user.username,
        'profileImage': user.profile,
        'caption': caption,
        'location': location,
        'uid': _auth.currentUser?.uid ?? '',
        'postId': postId,
        'likes': [],
        'time': FieldValue.serverTimestamp(),
      });

      return true;
    } on FirebaseException catch (e) {
      throw AppException(e.message ?? 'Error creating post');
    } catch (e) {
      throw AppException(e.toString());
    }
  }
  Future<void> deleteAccount() async {
  final currentUser = _auth.currentUser;
  if (currentUser == null) return;

  final uid = currentUser.uid;

  // eliminar posts
  final posts = await _firebaseFirestore
      .collection('posts')
      .where('uid', isEqualTo: uid)
      .get();

  for (var doc in posts.docs) {
    await doc.reference.delete();
  }

  // eliminar usuario
  await _firebaseFirestore
      .collection('users')
      .doc(uid)
      .delete();

  // eliminar auth
  await currentUser.delete();
}

  Future<void> updatePost({
    required String postId,
    required String caption,
    required String location,
  }) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw AppException('User not authenticated');

      final docRef = _firebaseFirestore.collection('posts').doc(postId);
      final snap = await docRef.get();

      if (!snap.exists) throw AppException('Post not found');

      final data = snap.data();
      if (data == null) throw AppException('Post data not found');

      if ((data['uid'] ?? '') != uid) {
        throw AppException('No tienes permiso para editar este post');
      }

      await docRef.update({
        'caption': caption.trim(),
        'location': location.trim(),
      });
    } on FirebaseException catch (e) {
      throw AppException(e.message ?? 'Error updating post');
    }
  }

  Future<void> deletePost({
    required String postId,
  }) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw AppException('User not authenticated');

      final postRef = _firebaseFirestore.collection('posts').doc(postId);
      final postSnap = await postRef.get();

      if (!postSnap.exists) return;

      final data = postSnap.data();
      if (data == null) return;

      if ((data['uid'] ?? '') != uid) {
        throw AppException('No tienes permiso para eliminar esta publicación');
      }

      final comments = await postRef.collection('comments').get();

      final batch = _firebaseFirestore.batch();

      for (final doc in comments.docs) {
        batch.delete(doc.reference);
      }

      batch.delete(postRef);

      await batch.commit();
    } on FirebaseException catch (e) {
      throw AppException(e.message ?? 'Error deleting post');
    }
  }

  Future<void> CreateReel({
    required String videoUrl,
    required String caption,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw AppException('User not authenticated');

    final postId = const Uuid().v4();

    try {
      final user = await getUser();

      await _firebaseFirestore.collection('stories').doc(postId).set({
        'videoUrl': videoUrl,
        'caption': caption,
        'username': user.username,
        'profileImage': user.profile,
        'uid': uid,
        'postId': postId,
        'time': FieldValue.serverTimestamp(),
        'likes': [],
        'views': 0,
      });
    } on FirebaseException catch (e) {
      throw AppException('Error de Firestore: ${e.message}');
    } catch (e) {
      throw AppException('Error al crear story: ${e.toString()}');
    }
  }

  Future<void> addComment({
    required String postId,
    required String comment,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw AppException('User not authenticated');

    final user = await getUser();
    final postDoc =
        await _firebaseFirestore.collection('posts').doc(postId).get();
    final postData = postDoc.data() ?? {};
    final postOwnerUid = (postData['uid'] ?? '') as String;
    final postImage = (postData['postImage'] ?? '') as String;

    final commentRef = await _firebaseFirestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .add({
      'comment': comment,
      'username': user.username,
      'uid': uid,
      'timestamp': FieldValue.serverTimestamp(),
    });

    if (postOwnerUid.isNotEmpty && postOwnerUid != uid) {
      await _createNotification(
        targetUid: postOwnerUid,
        notificationId: 'comment_${commentRef.id}',
        type: 'comment',
        fromUid: uid,
        fromUsername: user.username,
        fromProfileImage: user.profile,
        postId: postId,
        postImage: postImage,
        commentText: comment,
      );
    }
  }

  Stream<QuerySnapshot> getComments(String postId) {
    return _firebaseFirestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> updateComment({
    required String postId,
    required String commentId,
    required String newComment,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw AppException('User not authenticated');

    final docRef = _firebaseFirestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId);

    final snap = await docRef.get();
    final data = snap.data();

    if (data == null) throw AppException('Comment not found');

    if ((data['uid'] ?? '') != uid) {
      throw AppException('No tienes permiso para editar este comentario');
    }

    await docRef.update({
      'comment': newComment,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteComment({
    required String postId,
    required String commentId,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw AppException('User not authenticated');

    final docRef = _firebaseFirestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId);

    final snap = await docRef.get();
    final data = snap.data();

    if (data == null) throw AppException('Comment not found');

    if ((data['uid'] ?? '') != uid) {
      throw AppException('No tienes permiso para eliminar este comentario');
    }

    await docRef.delete();
  }

  Future<void> toggleSavePost({
    required String postId,
    required Map<String, dynamic> postData,
  }) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw AppException('User not authenticated');

      final savedRef = _firebaseFirestore
          .collection('users')
          .doc(uid)
          .collection('savedPosts')
          .doc(postId);

      final savedSnap = await savedRef.get();

      if (savedSnap.exists) {
        await savedRef.delete();
      } else {
        await savedRef.set({
          'postId': postId,
          'postImage': postData['postImage'] ?? '',
          'username': postData['username'] ?? '',
          'profileImage': postData['profileImage'] ?? '',
          'caption': postData['caption'] ?? '',
          'location': postData['location'] ?? '',
          'uid': postData['uid'] ?? '',
          'time': postData['time'],
          'savedAt': FieldValue.serverTimestamp(),
        });
      }
    } on FirebaseException catch (e) {
      throw AppException(e.message ?? 'Error saving post');
    }
  }

  Stream<bool> isPostSaved(String postId) {
    final uid = _auth.currentUser?.uid;

    if (uid == null) {
      return Stream.value(false);
    }

    return _firebaseFirestore
        .collection('users')
        .doc(uid)
        .collection('savedPosts')
        .doc(postId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  Stream<QuerySnapshot> getSavedPosts() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw AppException('User not authenticated');
    }

    return _firebaseFirestore
        .collection('users')
        .doc(uid)
        .collection('savedPosts')
        .orderBy('savedAt', descending: true)
        .snapshots();
  }

  Future<bool> isFollowingUser(String targetUid) async {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null) return false;

    final doc =
        await _firebaseFirestore.collection('users').doc(targetUid).get();
    final data = doc.data();

    if (data == null) return false;

    final followers = List.from(data['followers'] ?? []);
    return followers.contains(currentUid);
  }
  Stream<bool> isFollowingUserStream(String targetUid) {
  final currentUid = _auth.currentUser?.uid;

  if (currentUid == null || targetUid.isEmpty) {
    return Stream.value(false);
  }

  return _firebaseFirestore
      .collection('users')
      .doc(targetUid)
      .snapshots()
      .map((doc) {
    final data = doc.data();
    if (data == null) return false;

    final followers = List<String>.from(data['followers'] ?? []);
    return followers.contains(currentUid);
  });
}

  Stream<QuerySnapshot> getNotifications() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw AppException('User not authenticated');
    }

    return _firebaseFirestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}