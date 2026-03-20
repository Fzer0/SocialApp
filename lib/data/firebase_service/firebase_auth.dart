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
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw Exceptions('El usuario no existe.');
        case 'wrong-password':
          throw Exceptions('La contraseña es incorrecta.');
        case 'invalid-email':
          throw Exceptions('Correo inválido.');
        case 'invalid-credential':
          throw Exceptions('Correo o contraseña incorrectos.');
        case 'too-many-requests':
          throw Exceptions('Demasiados intentos. Intenta más tarde.');
        default:
          throw Exceptions(e.message ?? 'Error al iniciar sesión.');
      }
    } catch (_) {
      throw Exceptions('Error inesperado al iniciar sesión.');
    }
  }

  Future<void> ResetPassword({
    required String email,
  }) async {
    try {
      await _auth.sendPasswordResetEmail(
        email: email.trim(),
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw Exceptions('El usuario no existe.');
        case 'invalid-email':
          throw Exceptions('Correo inválido.');
        default:
          throw Exceptions(e.message ?? 'No se pudo enviar el correo.');
      }
    } catch (_) {
      throw Exceptions('Error inesperado al recuperar contraseña.');
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
      if (email.trim().isEmpty || username.trim().isEmpty || password.trim().isEmpty) {
        throw Exceptions('Completa los campos obligatorios.');
      }

      if (password != passwordConfirme) {
        throw Exceptions('Las contraseñas no coinciden.');
      }

      final UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final User? user = cred.user;
      if (user == null) {
        throw Exceptions('No se pudo crear el usuario.');
      }

      if (profile.path.isNotEmpty) {
        if (await profile.exists() && await profile.length() > 0) {
          url = (await StorageMetod().uploadImageToStorage('profile', profile)) ?? '';
        }
      }

      await FirebaseFirestor().CreateUser(
        email: email.trim(),
        username: username.trim(),
        bio: bio.trim(),
        profile: url.isEmpty
            ? 'https://firebasestorage.googleapis.com/v0/b/instagram-8a227.appspot.com/o/person.png?alt=media&token=c6fcbe9d-f502-4aa1-8b4b-ec37339e78ab'
            : url,
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          throw Exceptions('Ese correo ya está registrado.');
        case 'weak-password':
          throw Exceptions('La contraseña es muy débil.');
        case 'invalid-email':
          throw Exceptions('Correo inválido.');
        default:
          throw Exceptions(e.message ?? 'Error al registrar usuario.');
      }
    } catch (e) {
      if (e is Exceptions) rethrow;
      throw Exceptions('Error inesperado al registrarse.');
    }
  }
}