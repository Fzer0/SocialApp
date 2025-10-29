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
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
            child: Column(
              children: [
                SizedBox(height: 24.h),
                Center(child: Image.asset('images/logo_p.png', width: 120.w)),
                SizedBox(height: 28.h),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      children: [
                        _Textfild(email, email_F, 'Email', Icons.email),
                        SizedBox(height: 12.h),
                        _Textfild(password, password_F, 'Password', Icons.lock),
                        SizedBox(height: 8.h),
                        Align(alignment: Alignment.centerRight, child: _Forgot()),
                        SizedBox(height: 12.h),
                        _LoginButton(),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 18.h),
                _Have(),
              ],
            ),
          ),
        ),
      )
    );
  }

  Widget _Have() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            "Don't have account? ",
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey,
            ),
          ),
          GestureDetector(
            onTap: widget.show,
            child: Text(
              "Sign up ",
              style: TextStyle(
                fontSize: 15.sp,
                color: Colors.blue,
                fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _LoginButton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: InkWell(
        onTap: () async {
          try {
            await Authentication().Login(email: email.text, password: password.text);
          } on exceptions catch (e) {
            // CORRECCIÓN CLAVE: usar la propiedad 'message' de la excepción personalizada
            dialogBuilder(context, e.message);
          }
        },
        child: Container(
          alignment: Alignment.center,
          width: double.infinity,
          height: 44.h,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Text(
            'Login',
            style: TextStyle(
              fontSize: 23.sp,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _Forgot() {
    return Padding(
      padding: EdgeInsets.only(right: 8.w),
      child: GestureDetector(
        onTap: () async {
          // Mostrar diálogo para confirmar el correo y enviar el email de recuperación
          String typedEmail = email.text.trim();
          final controller = TextEditingController(text: typedEmail);
          final result = await showDialog<bool>(
            context: context,
            builder: (c) => AlertDialog(
              title: const Text('Reset password'),
              content: TextField(
                controller: controller,
                decoration: const InputDecoration(hintText: 'Enter your email'),
                keyboardType: TextInputType.emailAddress,
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('Cancel')),
                TextButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('Send')),
              ],
            ),
          );

          if (result == true) {
            final mail = controller.text.trim();
            if (mail.isEmpty) {
              dialogBuilder(context, 'Please enter your email address');
              return;
            }
            try {
              await Authentication().ResetPassword(email: mail);
              dialogBuilder(context, 'Password reset email sent. Check your inbox.');
            } on exceptions catch (e) {
              dialogBuilder(context, e.message);
            }
          }
        },
        child: Text(
          'Forgot password?',
          style: TextStyle(
            fontSize: 13.sp,
            color: Colors.blue,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _Textfild(TextEditingController controll, FocusNode focusNode,
      String typename, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: Container(
        height: 44.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5.r),
        ),
        child: TextField(
          style: TextStyle(fontSize: 18.sp, color: Colors.black),
          controller: controll,
          focusNode: focusNode,
          obscureText: typename.toLowerCase().contains('password') ? _obscurePassword : false,
          decoration: InputDecoration(
            hintText: typename,
            prefixIcon: Icon(
              icon,
              color: focusNode.hasFocus ? Colors.black : Colors.grey[600],
            ),
            suffixIcon: typename.toLowerCase().contains('password')
                ? IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  )
                : null,
            contentPadding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 15.h),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5.r),
              borderSide: BorderSide(
                width: 2.w,
                color: Colors.grey,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5.r),
              borderSide: BorderSide(
                width: 2.w,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}