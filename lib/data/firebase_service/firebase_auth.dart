import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app/data/firebase_service/firestor.dart';
import 'package:app/data/firebase_service/storage.dart';
import 'package:app/util/exeption.dart';

class Authentication {
  FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> Login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email.trim(), password: password.trim());
    } on FirebaseException catch (e) {
      // Usando 'e.message' (campo renombrado en la excepción personalizada)
      throw exceptions(e.message.toString()); 
    }
  }

  /// Enviar correo para restablecer contraseña.
  Future<void> ResetPassword({
    required String email,
  }) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseException catch (e) {
      throw exceptions(e.message.toString());
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
    // Inicializar como cadena vacía para evitar problemas de null-safety
    String URL = '';
    try {
      if (email.isNotEmpty && password.isNotEmpty && username.isNotEmpty && bio.isNotEmpty) {
        if (password == passwordConfirme) {
          await _auth.createUserWithEmailAndPassword(
            email: email.trim(),
            password: password.trim(),
          );

          // Asegurar que el currentUser está actualizado antes de subir la foto de perfil
          try {
            await _auth.currentUser?.reload();
          } catch (e) {
            // No bloquear el registro por un fallo de reload, solo loguearlo
            print('Warning: failed to reload currentUser after signup: $e');
          }
          print('Signup - currentUser uid after create: ${_auth.currentUser?.uid}');

          // Lógica correcta: si hay path, subir imagen.
          if (profile.path.isNotEmpty) {
            // Intentar subir la imagen de perfil con un reintento si falla una vez.
            URL = (await StorageMetod().uploadImageToStorage('profile', profile)) ?? '';
            if (URL.isEmpty) {
              print('Profile upload returned empty URL, retrying once...');
              await Future.delayed(const Duration(seconds: 1));
              URL = (await StorageMetod().uploadImageToStorage('profile', profile)) ?? '';
            }

            if (URL.isEmpty) {
              // Si no se subió, lanzar excepción para informar al usuario.
              throw exceptions('No se pudo subir la foto de perfil. Intenta nuevamente.');
            }
          } else {
            URL = '';
          }

          await Firebase_Firestor().CreateUser(
            email: email,
            username: username,
            bio: bio,
            profile: URL.isEmpty
                ? 'https://firebasestorage.googleapis.com/v0/b/instagram-8a227.appspot.com/o/person.png?alt=media&token=c6fcbe9d-f502-4aa1-8b4b-ec37339e78ab'
                : URL,
          );
        } else {
          throw exceptions("Password and confirm password should be the same");
        }
      } else {
        throw exceptions('enter all the fields');
      }
    } on FirebaseException catch (e) {
      // Usando 'e.message' (campo renombrado en la excepción personalizada)
      throw exceptions(e.message.toString()); 
    }
  }
}