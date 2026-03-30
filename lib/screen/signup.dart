import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:app/data/firebase_service/firebase_auth.dart';
import 'package:app/util/dialog.dart';
import 'package:app/util/exeption.dart';
import 'package:app/util/imagepicker.dart';
import 'package:app/widgets/auth_shell.dart';
import 'package:app/widgets/auth_input.dart';
import 'package:app/widgets/auth_button.dart';

class SignupScreen extends StatefulWidget {
  final VoidCallback showLogin;
  final VoidCallback showWelcome;

  const SignupScreen({
    super.key,
    required this.showLogin,
    required this.showWelcome,
  });

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  final bio = TextEditingController();
  final username = TextEditingController();
  final passwordConfirme = TextEditingController();

  File? _imageFile;
  bool _loading = false;
  bool _obscure1 = true;
  bool _obscure2 = true;

  Future<void> _signup() async {
    if (username.text.trim().isEmpty) {
      dialogBuilder(context, 'Ingresa tu nombre de usuario');
      return;
    }

    if (email.text.trim().isEmpty) {
      dialogBuilder(context, 'Ingresa tu correo');
      return;
    }

    if (password.text.trim().isEmpty) {
      dialogBuilder(context, 'Ingresa tu contraseña');
      return;
    }

    if (passwordConfirme.text.trim().isEmpty) {
      dialogBuilder(context, 'Confirma tu contraseña');
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      await Authentication().Signup(
        email: email.text,
        password: password.text,
        passwordConfirme: passwordConfirme.text,
        username: username.text,
        bio: bio.text,
        profile: _imageFile ?? File(''),
      );

      if (mounted) {
        dialogBuilder(context, '¡Registro exitoso! Ahora inicia sesión.');
        widget.showLogin();
      }
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

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    bio.dispose();
    username.dispose();
    passwordConfirme.dispose();
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
          SizedBox(height: 10.h),
          GestureDetector(
            onTap: () async {
              File? pickedImage = await ImagePickerr().uploadImage('gallery');
              if (pickedImage != null) {
                setState(() {
                  _imageFile = pickedImage;
                });
              }
            },
            child: CircleAvatar(
              radius: 42.r,
              backgroundColor: Colors.white.withOpacity(0.9),
              backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
              child: _imageFile == null
                  ? Icon(Icons.person_add_alt_1, color: Colors.grey.shade700, size: 34.sp)
                  : null,
            ),
          ),
          SizedBox(height: 14.h),
          Text(
            'Crear Nueva Cuenta',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 24.h),
          AuthInput(
            controller: username,
            hint: 'Usuario',
            icon: Icons.person_outline,
          ),
          AuthInput(
            controller: email,
            hint: 'Correo electronico',
            icon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
          ),
          AuthInput(
            controller: bio,
            hint: 'Biografia',
            icon: Icons.edit_note,
          ),
          AuthInput(
            controller: password,
            hint: 'Contraseña',
            icon: Icons.lock_outline,
            obscureText: _obscure1,
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _obscure1 = !_obscure1;
                });
              },
              icon: Icon(
                _obscure1 ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          AuthInput(
            controller: passwordConfirme,
            hint: 'Confirmar contraseña',
            icon: Icons.lock_outline,
            obscureText: _obscure2,
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _obscure2 = !_obscure2;
                });
              },
              icon: Icon(
                _obscure2 ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          SizedBox(height: 8.h),
          AuthButton(
            text: 'Registrarse',
            onTap: _signup,
            loading: _loading,
          ),
          SizedBox(height: 10.h),
          GestureDetector(
            onTap: widget.showLogin,
            child: Text(
              '¿Ya tienes cuenta? Acceso',
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