import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:app/widgets/auth_shell.dart';
import 'package:app/widgets/auth_button.dart';

class WelcomeScreen extends StatelessWidget {
  final VoidCallback onLogin;
  final VoidCallback onSignup;

  const WelcomeScreen({
    super.key,
    required this.onLogin,
    required this.onSignup,
  });

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 40.h),
          Text(
            'MINGLE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'Conecta, comparte y descubre.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 220.h),
          AuthButton(
            text: 'Sign In',
            onTap: onLogin,
          ),
          AuthButton(
            text: 'Sign Up',
            onTap: onSignup,
            outlined: true,
          ),
          SizedBox(height: 8.h),
          Text(
            'Bienvenido a tu red social',
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }
}