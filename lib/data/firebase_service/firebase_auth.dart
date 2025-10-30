// firebase_auth.dart

import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app/data/firebase_service/firestor.dart';
import 'package:app/data/firebase_service/storage.dart';
import 'package:app/util/exeption.dart';

class Authentication {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> Login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email.trim(), password: password.trim());
    } on FirebaseException catch (e) {
      throw Exceptions(e.message.toString());
    }
  }

  Future<void> ResetPassword({
    required String email,
  }) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseException catch (e) {
      throw Exceptions(e.message.toString());
    }
  }

  Future<void> Signup({
    required String email,
    required String password,
    required String passwordConfirme,
    required String username,
    required String bio,
    required File profile,
  }) async {
    String url = '';
    try {
      if (email.isNotEmpty && password.isNotEmpty && username.isNotEmpty && bio.isNotEmpty) {
        if (password == passwordConfirme) {
          
          // 1. Crear el usuario (Auth)
          final UserCredential cred = await _auth.createUserWithEmailAndPassword(
            email: email.trim(),
            password: password.trim(),
          );

          // OBTENER Y VERIFICAR EL UID INMEDIATAMENTE
          final User? user = cred.user; // Usamos el UserCredential para mayor certeza.
          if (user == null) {
            throw Exceptions('Registration successful but user object is null.');
          }
          final String uid = user.uid;
          
          // ⚠️ AÑADIR RETRASO ESTRATÉGICO PARA SINCRONIZACIÓN DE FIREBASE AUTH/STORAGE
          await Future.delayed(const Duration(milliseconds: 500));

          // 2. Subir la imagen
          if (profile.path.isNotEmpty) {
            
            if (await profile.exists() && await profile.length() > 0) {
              url = (await StorageMetod().uploadImageToStorage('profile', profile)) ?? '';
            } else {
              // Warning: Profile file is empty or does not exist, skipping upload.
            }

            if (url.isEmpty && profile.path.isNotEmpty) {
              // Si la subida fue intentada pero falló, lanzar excepción
              throw Exceptions('No se pudo subir la foto de perfil. Intenta nuevamente.');
            }
          }

          // 3. Crear el documento de usuario en Firestore
          await FirebaseFirestor().CreateUser(
            email: email,
            username: username,
            bio: bio,
            profile: url.isEmpty
                ? 'https://firebasestorage.googleapis.com/v0/b/instagram-8a227.appspot.com/o/person.png?alt=media&token=c6fcbe9d-f502-4aa1-8b4b-ec37339e78ab'
                : url,
          );
        } else {
          throw Exceptions("Password and confirm password should be the same");
        }
      } else {
        throw Exceptions('enter all the fields');
      }
    } on FirebaseException catch (e) {
      throw Exceptions(e.message.toString());
    }
  }
}