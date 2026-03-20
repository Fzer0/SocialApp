import 'package:flutter/material.dart';
import 'package:app/screen/login_screen.dart';
import 'package:app/screen/signup.dart';
import 'package:app/screen/welcome_screen.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  int currentPage = 0;

  void _changePage(int page) {
    if (!mounted) return;
    if (currentPage == page) return;

    setState(() {
      currentPage = page;
    });
  }

  void showWelcome() => _changePage(0);
  void showLogin() => _changePage(1);
  void showSignup() => _changePage(2);

  @override
  Widget build(BuildContext context) {
    switch (currentPage) {
      case 0:
        return WelcomeScreen(
          onLogin: showLogin,
          onSignup: showSignup,
        );
      case 1:
        return LoginScreen(
          showSignup: showSignup,
          showWelcome: showWelcome,
        );
      case 2:
        return SignupScreen(
          showLogin: showLogin,
          showWelcome: showWelcome,
        );
      default:
        return WelcomeScreen(
          onLogin: showLogin,
          onSignup: showSignup,
        );
    }
  }
}