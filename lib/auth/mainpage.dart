import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:app/widgets/navigation.dart';
import 'package:app/auth/auth_screen.dart';
import 'package:app/firebase_options.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  bool _trying = false;

  Future<void> _retryInit() async {
    setState(() => _trying = true);
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
        print('Firebase re-initialized from MainPage retry');
      }
    } catch (e, st) {
      print('Retry Firebase init error: $e');
      print(st);
    } finally {
      setState(() => _trying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Estado inicial: esperando la primera emisión
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Mostrar error si el stream falla
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Error en auth stream: ${snapshot.error}'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _trying ? null : _retryInit,
                      child: _trying ? const CircularProgressIndicator() : const Text('Reintentar inicialización'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Si hay datos, ir a navegación; sino, a autenticación
          if (snapshot.hasData) {
            return const NavigationScreen();
          } else {
            return const AuthPage();
          }
        },
      ),
    );
  }
}