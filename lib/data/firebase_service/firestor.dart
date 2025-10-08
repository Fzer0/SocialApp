import 'package:app/data/model/usermodel.dart';
import 'package:app/util/exeption.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class Firebase_Firestor {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance; // Fix: The instance method was not called correctly.
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<bool> CreateUser({
    required String email,
    required String username,
    required String bio,
    required String profile,
  }) async {
    await _firebaseFirestore.collection('users').doc(_auth.currentUser!.uid).set({
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
    final user = await _firebaseFirestore
        .collection('user')
        .doc(_auth.currentUser!.uid)
        .get();
    final snapuser = user.data()!;
    return Usermodel(
      email: snapuser['email'],
      username: snapuser['username'],
      bio: snapuser['bio'],
      profile: snapuser['profile'],
      followers: snapuser['followers'],
      following: snapuser['following'],
    );
  } on FirebaseException catch (e) {
    throw exceptions(e.message.toString());
  }
}
  Future<bool> CreatePost({
    required String postImage,
    required String caption,
    required String location,
  }) async{
    var uid = Uuid().v4();
    DateTime data = DateTime.now();
    Usermodel user = await getUser();
    await _firebaseFirestore.collection('posts').doc(uid).set({
      'postImage': postImage,
      'username': user.username,
      'profileImage':user.profile,
      'caption': caption,
      'location': location,
      'uid' : _auth.currentUser!.uid,
      'postId': uid,
      'likes': [],
      'time': data,
      });
      return true;
  }
}