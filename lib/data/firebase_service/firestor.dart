import 'package:app/data/model/usermodel.dart';
// import 'package:app/util/exeption.dart'; // Eliminado para evitar conflictos de importación
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

// Definición de una clase de excepción personalizada para reemplazar la función 'exceptions'
// Esto asegura que la clase sea self-contained y resuelve el error de compilación.
class AppException implements Exception {
  final String message;
  AppException(this.message);
  @override
  String toString() => 'AppException: $message';
}

class FirebaseFirestor {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance; // Fix: The instance method was not called correctly.
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Like or unlike a post (toggle)
  Future<void> toggleLike({required String postId}) async {
    try {
      final uid = _auth.currentUser?.uid;
      // Reemplazando 'exceptions' por 'AppException'
      if (uid == null) throw AppException('User not authenticated'); 
      final docRef = _firebaseFirestore.collection('posts').doc(postId);
      final snap = await docRef.get();
      if (!snap.exists) return;
      final likes = List.from(snap.data()?['likes'] ?? []);
      if (likes.contains(uid)) {
        await docRef.update({'likes': FieldValue.arrayRemove([uid])});
        print('Firestore: removed like for post $postId by $uid');
      } else {
        await docRef.update({'likes': FieldValue.arrayUnion([uid])});
        print('Firestore: added like for post $postId by $uid');
      }
    } on FirebaseException catch (e) {
      print('Firestore toggleLike failed: ${e.code} ${e.message}');
      rethrow;
    }
  }

  // Follow a user
  Future<void> followUser({required String targetUid}) async {
    try {
      final uid = _auth.currentUser?.uid;
      // Reemplazando 'exceptions' por 'AppException'
      if (uid == null) throw AppException('User not authenticated');
      if (uid == targetUid) return;
      final targetRef = _firebaseFirestore.collection('users').doc(targetUid);
      final meRef = _firebaseFirestore.collection('users').doc(uid);
      await targetRef.update({'followers': FieldValue.arrayUnion([uid])});
      await meRef.update({'following': FieldValue.arrayUnion([targetUid])});
      print('Firestore: $uid followed $targetUid');
    } on FirebaseException catch (e) {
      print('Firestore followUser failed: ${e.code} ${e.message}');
      rethrow;
    }
  }

  // Unfollow a user
  Future<void> unfollowUser({required String targetUid}) async {
    try {
      final uid = _auth.currentUser?.uid;
      // Reemplazando 'exceptions' por 'AppException'
      if (uid == null) throw AppException('User not authenticated');
      if (uid == targetUid) return;
      final targetRef = _firebaseFirestore.collection('users').doc(targetUid);
      final meRef = _firebaseFirestore.collection('users').doc(uid);
      await targetRef.update({'followers': FieldValue.arrayRemove([uid])});
      await meRef.update({'following': FieldValue.arrayRemove([targetUid])});
      print('Firestore: $uid unfollowed $targetUid');
    } on FirebaseException catch (e) {
      print('Firestore unfollowUser failed: ${e.code} ${e.message}');
      rethrow;
    }
  }

  Future<bool> CreateUser({
    required String email,
    required String username,
    required String bio,
    required String profile,
  }) async {
    final uid = _auth.currentUser?.uid;
    // Reemplazando 'exceptions' por 'AppException'
    if (uid == null) throw AppException('User not authenticated');
    await _firebaseFirestore.collection('users').doc(uid).set({
      'email': email,
      'username': username,
      'bio': bio,
      'profile': profile,
      'followers': [],
      'following': [],
    });
    return true;
  }
  Future<Usermodel> getUser() async {
  try {
    // Usar la colección 'users' (plural) para ser coherente con CreateUser
    final uid = _auth.currentUser?.uid;
    // Reemplazando 'exceptions' por 'AppException'
    if (uid == null) throw AppException('User not authenticated');
    final user = await _firebaseFirestore.collection('users').doc(uid).get();
    final snapuser = user.data();
    // Reemplazando 'exceptions' por 'AppException'
    if (snapuser == null) throw AppException('User document not found');
    return Usermodel(
      email: snapuser['email'],
      username: snapuser['username'],
      bio: snapuser['bio'],
      profile: snapuser['profile'],
      followers: snapuser['followers'],
      following: snapuser['following'],
    );
  } on FirebaseException catch (e) {
    // Reemplazando 'exceptions' por 'AppException'
    throw AppException(e.message.toString());
  }
}
  Future<bool> CreatePost({
    required String postImage,
    required String caption,
    required String location,
  }) async{
    var uid = Uuid().v4();
    DateTime data = DateTime.now();
    try {
      Usermodel user;
      try {
        user = await getUser();
      } catch (e) {
        // Si no existe el documento de usuario, no queremos fallar la subida del post.
        // Usar valores por defecto basados en el usuario autenticado cuando sea posible.
        print('Warning: could not fetch user document, using fallback values: $e');
        final authUser = _auth.currentUser;
        user = Usermodel(
          email: authUser?.email ?? '',
          username: authUser?.displayName ?? (authUser?.email?.split('@').first ?? 'user'),
          bio: '',
          profile: 'https://firebasestorage.googleapis.com/v0/b/instagram-8a227.appspot.com/o/person.png?alt=media&token=c6fcbe9d-f502-4aa1-8b4b-ec37339e78ab',
          followers: [],
          following: [],
        );
      }
      final docRef = _firebaseFirestore.collection('posts').doc(uid);
      final payload = {
        'postImage': postImage,
        'username': user.username,
        'profileImage': user.profile,
        'caption': caption,
        'location': location,
        'uid': _auth.currentUser?.uid ?? '',
        'postId': uid,
        'likes': [],
        'time': data,
      };
      await docRef.set(payload);
      print('✅ Firestore CreatePost succeeded: doc=${docRef.path} payload=${payload}');
      return true;
    } on FirebaseException catch (e) {
      print('❌ Firestore CreatePost failed: code=${e.code} message=${e.message}');
      rethrow;
    } catch (e) {
      print('❌ Firestore CreatePost unexpected error: $e');
      rethrow;
    }
  }

  // Obtener Usermodel por uid (para ver perfiles de otros)
  Future<Usermodel> getUserById(String uid) async {
    try {
      final doc = await _firebaseFirestore.collection('users').doc(uid).get();
      final data = doc.data();
      if (data == null) throw Exception('User not found');
      return Usermodel(
        email: (data['email'] ?? '') as String,
        username: (data['username'] ?? '') as String,
        bio: (data['bio'] ?? '') as String,
        profile: (data['profile'] ?? '') as String,
        followers: (data['followers'] ?? []) as List,
        following: (data['following'] ?? []) as List,
      );
    } on FirebaseException catch (e) {
      // Reemplazando 'exceptions' por 'AppException'
      throw AppException(e.message.toString());
    }
  }

  // Nuevo método para crear un "Reel" o "Story"
  Future<void> CreateReel({
    required String videoUrl,
    required String caption,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw AppException('User not authenticated');

    var postId = Uuid().v4();
    DateTime timestamp = DateTime.now();

    try {
      // Obtener datos del usuario para el post
      Usermodel user = await getUser();

      final payload = {
        'videoUrl': videoUrl,
        'caption': caption,
        'username': user.username,
        'profileImage': user.profile,
        'uid': uid,
        'postId': postId,
        'time': timestamp,
        'likes': [],
        'views': 0, // Añadir contador de vistas
      };

      // Guardar en una colección separada para stories/reels
      await _firebaseFirestore.collection('stories').doc(postId).set(payload);
      print('✅ Firestore CreateReel succeeded: doc=stories/$postId');
    } on FirebaseException catch (e) {
      print('❌ Firestore CreateReel failed: code=${e.code} message=${e.message}');
      throw AppException('Error de Firestore: ${e.message}');
    } catch (e) {
      print('❌ Firestore CreateReel unexpected error: $e');
      throw AppException('Error al crear story: ${e.toString()}');
    }
  }

  // Nuevo método para agregar un comentario a un post
  Future<void> addComment({
    required String postId,
    required String comment,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw AppException('User not authenticated');

    // Obtener el username desde Firestore para consistencia
    final user = await getUser();

    await _firebaseFirestore.collection('posts').doc(postId).collection('comments').add({
      'comment': comment,
      'username': user.username,
      'uid': uid,
      'timestamp': FieldValue.serverTimestamp(),
    });
    print('Firestore addComment succeeded: postId=$postId uid=$uid');
  }

  // Método para obtener comentarios de un post
  Stream<QuerySnapshot> getComments(String postId) {
    return _firebaseFirestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Nuevo método para actualizar un comentario
  Future<void> updateComment({
    required String postId,
    required String commentId,
    required String newComment,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw AppException('User not authenticated');

    await _firebaseFirestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .update({
          'comment': newComment,
          'timestamp': FieldValue.serverTimestamp(),
        });
    print('Firestore updateComment succeeded: postId=$postId commentId=$commentId uid=$uid');
  }

  // Nuevo método para eliminar un comentario
  Future<void> deleteComment({
    required String postId,
    required String commentId,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw AppException('User not authenticated');

    await _firebaseFirestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .delete();
    print('Firestore deleteComment succeeded: postId=$postId commentId=$commentId uid=$uid');
  }

  // Nuevo método para eliminar un post
  Future<void> deletePost({
    required String postId,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw AppException('User not authenticated');

    await _firebaseFirestore.collection('posts').doc(postId).delete();
    print('Firestore deletePost succeeded: postId=$postId uid=$uid');
  }
}
