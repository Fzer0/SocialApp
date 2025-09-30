// En el archivo: social_app/widgets/navigation.dart (o donde lo tengas)

import 'package:flutter/material.dart';
import 'package:app/screen/add_screen.dart'; // Importa AddScreen
import 'package:app/screen/home.dart';
import 'package:app/screen/profile_screen.dart';
import 'package:app/screen/reelsScreen.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  int _currentIndex = 0;
  late PageController pageController;

  @override
  void initState() {
    super.initState();
    pageController = PageController();
  }

  @override
  void dispose() {
    super.dispose();
    pageController.dispose();
  }

  void onPageChanged(int page) {
    setState(() {
      _currentIndex = page;
    });
  }

  void navigationTapped(int page) {
    pageController.jumpToPage(page);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black,
        currentIndex: _currentIndex,
        onTap: navigationTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '',
          ),
          // Ahora el ícono de la cámara navega a la pantalla de añadir
          BottomNavigationBarItem(
            icon: Icon(Icons.add_a_photo), 
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '',
          ),
        ],
      ),
      body: PageView(
        controller: pageController,
        onPageChanged: onPageChanged,
        children: const [
          HomeScreen(),
          AddScreen(), // Muestra la pantalla de añadir
          ProfileScreen(),
        ],
      ),
    );
  }
}