import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:app/data/firebase_service/firebase_auth.dart';
import 'package:app/util/exeption.dart';
import 'package:app/util/dialog.dart';
import 'package:app/widgets/auth_shell.dart';
import 'package:app/widgets/auth_input.dart';
import 'package:app/widgets/auth_button.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback showSignup;
  final VoidCallback showWelcome;

  const LoginScreen({
    super.key,
    required this.showSignup,
    required this.showWelcome,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();

  bool _loading = false;
  bool _obscure = true;

  Future<void> _login() async {
    if (email.text.trim().isEmpty) {
      dialogBuilder(context, 'Ingresa tu correo');
      return;
    }

    if (password.text.trim().isEmpty) {
      dialogBuilder(context, 'Ingresa tu contraseña');
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      await Authentication().Login(
        email: email.text,
        password: password.text,
      );
    } on Exceptions catch (e) {
      dialogBuilder(context, e.message);
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    final controller = TextEditingController(text: email.text.trim());

    final result = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Recuperar contraseña'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Correo electrónico',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Enviar'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      if (controller.text.trim().isEmpty) {
        dialogBuilder(context, 'Ingresa tu correo');
        return;
      }

      try {
        await Authentication().ResetPassword(
          email: controller.text.trim(),
        );
        dialogBuilder(context, 'Se envió el correo de recuperación.');
      } on Exceptions catch (e) {
        dialogBuilder(context, e.message);
      }
    }
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: widget.showWelcome,
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          SizedBox(height: 18.h),
          Text(
            'Bienvenido a Mingle',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            'Ingresa tus datos para continuar',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13.sp,
            ),
          ),
          SizedBox(height: 28.h),
          AuthInput(
            controller: email,
            hint: 'Usuario o Correo',
            icon: Icons.person_outline,
            keyboardType: TextInputType.emailAddress,
          ),
          AuthInput(
            controller: password,
            hint: 'Contraseña',
            icon: Icons.lock_outline,
            obscureText: _obscure,
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _obscure = !_obscure;
                });
              },
              icon: Icon(
                _obscure ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          SizedBox(height: 8.h),
          AuthButton(
            text: 'Acceder',
            onTap: _login,
            loading: _loading,
          ),
          SizedBox(height: 6.h),
          GestureDetector(
            onTap: _resetPassword,
            child: Text(
              '¿Olvidaste tu contraseña?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(height: 26.h),
          GestureDetector(
            onTap: widget.showSignup,
            child: Text(
              '¿No tienes cuenta? Registrate',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}