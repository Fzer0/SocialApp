import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:app/widgets/navigation.dart';
import 'package:app/auth/auth_screen.dart'; 

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            // Muestra la pantalla de navegación si el usuario está conectado
            return const NavigationScreen(); 
          } else {
            // Muestra la pantalla de autenticación si no está conectado
            return const AuthPage(); 
          }
        },
      ),
    );
  }
}