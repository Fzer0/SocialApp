// login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:app/data/firebase_service/firebase_auth.dart';
import 'package:app/util/exeption.dart';
import 'package:app/util/dialog.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback show;
  const LoginScreen(this.show, {super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  FocusNode email_F = FocusNode();
  final password = TextEditingController();
  FocusNode password_F = FocusNode();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    email_F.addListener(() => setState(() {}));
    password_F.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    email_F.dispose();
    password_F.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFAFAFA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 40.h),
                
                // Logo con efecto
                Center(
                  child: Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF667EEA).withOpacity(0.1),
                          Color(0xFF764BA2).withOpacity(0.1),
                        ],
                      ),
                    ),
                    child: Image.asset(
                      'images/logo_p.png',
                      width: 80.w,
                      height: 80.w,
                    ),
                  ),
                ),
                
                SizedBox(height: 40.h),
                
                // Header
                Text(
                  'Bienvenido',
                  style: TextStyle(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'Inicia sesión para continuar',
                  style: TextStyle(
                    fontSize: 15.sp,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400,
                  ),
                ),
                
                SizedBox(height: 40.h),
                
                // Formulario
                _buildTextField(
                  controller: email,
                  focusNode: email_F,
                  hint: 'Correo electrónico',
                  icon: Icons.mail_outline,
                ),
                
                SizedBox(height: 16.h),
                
                _buildTextField(
                  controller: password,
                  focusNode: password_F,
                  hint: 'Contraseña',
                  icon: Icons.lock_outline,
                  isPassword: true,
                ),
                
                SizedBox(height: 12.h),
                
                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: _buildForgotPassword(),
                ),
                
                SizedBox(height: 32.h),
                
                // Login button
                _buildLoginButton(),
                
                SizedBox(height: 24.h),
                
                // Divider con texto
                _buildDivider(),
                
                SizedBox(height: 24.h),
                
                // Signup link
                _buildSignupLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    bool isFocused = focusNode.hasFocus;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isFocused ? Colors.black87 : Colors.grey[300]!,
          width: isFocused ? 2 : 1,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                )
              ]
            : [],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: isPassword && _obscurePassword,
        style: TextStyle(
          fontSize: 16.sp,
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(
            icon,
            color: isFocused ? Colors.black87 : Colors.grey[400],
            size: 22.w,
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: Colors.grey[400],
                    size: 22.w,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 16.h,
          ),
        ),
      ),
    );
  }

  Widget _buildForgotPassword() {
    return GestureDetector(
      onTap: () async {
        String typedEmail = email.text.trim();
        final controller = TextEditingController(text: typedEmail);
        
        final result = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
            title: Text(
              'Recuperar contraseña',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 20.sp,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Te enviaremos un enlace de recuperación',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: 'Correo electrónico',
                    prefixIcon: Icon(Icons.mail_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: BorderSide(color: Color(0xFF667EEA), width: 2),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(c).pop(false),
                child: Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(c).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF667EEA),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Text('Enviar'),
              ),
            ],
          ),
        );

        if (result == true) {
          final mail = controller.text.trim();
          if (mail.isEmpty) {
            dialogBuilder(context, 'Por favor ingresa tu correo');
            return;
          }
          try {
            await Authentication().ResetPassword(email: mail);
            dialogBuilder(context, 'Email enviado. Revisa tu bandeja de entrada.');
          } on exceptions catch (e) {
            dialogBuilder(context, e.message);
          }
        }
      },
      child: Text(
        '¿Olvidaste tu contraseña?',
        style: TextStyle(
          fontSize: 14.sp,
          color: Color(0xFF667EEA),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return GestureDetector(
      onTap: () async {
        try {
          await Authentication().Login(
            email: email.text,
            password: password.text,
          );
        } on exceptions catch (e) {
          dialogBuilder(context, e.message);
        }
      },
      child: Container(
        width: double.infinity,
        height: 54.h,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF667EEA),
              Color(0xFF764BA2),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF667EEA).withOpacity(0.3),
              blurRadius: 15,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'Iniciar sesión',
            style: TextStyle(
              fontSize: 17.sp,
              color: Colors.white,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: Colors.grey[300],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            'o',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.grey[300],
          ),
        ),
      ],
    );
  }

  Widget _buildSignupLink() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '¿No tienes cuenta? ',
            style: TextStyle(
              fontSize: 15.sp,
              color: Colors.grey[600],
              fontWeight: FontWeight.w400,
            ),
          ),
          GestureDetector(
            onTap: widget.show,
            child: Text(
              'Regístrate',
              style: TextStyle(
                fontSize: 15.sp,
                color: Color(0xFF667EEA),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}