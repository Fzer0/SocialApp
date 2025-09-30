import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:app/auth/mainpage.dart';
import 'package:app/screen/home.dart'; // Importa el paquete de Firebase Core

void main() async { // La función main debe ser asíncrona
  WidgetsFlutterBinding.ensureInitialized(); // Asegura la inicialización del framework
  await Firebase.initializeApp(); // Inicializa Firebase 
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