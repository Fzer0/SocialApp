import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:app/firebase_options.dart';
import 'package:app/auth/mainpage.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Evita inicializar Firebase más de una vez (causa: "[core/duplicate-app]")
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      // Log de verificación para depuración
      // Ver en la consola: "Firebase initialized"
      // print('Firebase initialized');
    }
    // Activar App Check en modo debug (desarrollo). Esto evitará 403 si App Check
    // está en enforcement en la consola y estás probando desde un dispositivo.
    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.debug,
        appleProvider: AppleProvider.debug,
      );
      // print('Firebase App Check activated (debug provider)');
    } catch (e) {
      // print('FirebaseAppCheck activation failed: $e');
    }
  } catch (e, st) {
    // Mostrar en consola cualquier error durante la inicialización
    // print('Firebase initialization error: $e');
    // print(st);
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ScreenUtilInit(
        designSize: const Size(375, 812),
        child: const MainPage(),
      ),
    );
  }
}