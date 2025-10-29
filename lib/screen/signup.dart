// signup.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:app/data/firebase_service/firebase_auth.dart';
import 'package:app/util/dialog.dart';
import 'package:app/util/exeption.dart';
import 'package:app/util/imagepicker.dart';

class SignupScreen extends StatefulWidget {
  final VoidCallback show;
  SignupScreen(this.show, {super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final email = TextEditingController();
  FocusNode email_F = FocusNode();
  final password = TextEditingController();
  FocusNode password_F = FocusNode();
  final bio = TextEditingController();
  FocusNode bio_F = FocusNode();
  final username = TextEditingController();
  FocusNode username_F = FocusNode();
  final passwordConfirme = TextEditingController();
  FocusNode passwordConfirme_F = FocusNode();

  File? _imageFile;

  @override
  void initState() {
    super.initState();
    email_F.addListener(() => setState(() {}));
    password_F.addListener(() => setState(() {}));
    bio_F.addListener(() => setState(() {}));
    username_F.addListener(() => setState(() {}));
    passwordConfirme_F.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    bio.dispose();
    username.dispose();
    passwordConfirme.dispose();
    email_F.dispose();
    password_F.dispose();
    bio_F.dispose();
    username_F.dispose();
    passwordConfirme_F.dispose();
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
                SizedBox(height: 20.h),
                // Header minimalista
                Text(
                  'Mingle',
                  style: TextStyle(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 32.h),
                
                // Avatar con diseño más moderno
                Center(
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF667EEA),
                              Color(0xFF764BA2),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        padding: EdgeInsets.all(3.w),
                        child: CircleAvatar(
                          radius: 50.r,
                          backgroundColor: Color(0xFFFAFAFA),
                          child: _imageFile == null
                              ? Icon(
                                  Icons.person_outline,
                                  size: 40.w,
                                  color: Colors.grey[400],
                                )
                              : ClipOval(
                                  child: Image.file(
                                    _imageFile!,
                                    fit: BoxFit.cover,
                                    width: 100.w,
                                    height: 100.w,
                                  ),
                                ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () async {
                            File? pickedImage = await ImagePickerr().uploadImage('gallery');
                            setState(() {
                              _imageFile = pickedImage;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              size: 18.w,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 36.h),
                
                // Formulario
                _buildTextField(
                  controller: username,
                  focusNode: username_F,
                  hint: 'Nombre de usuario',
                  icon: Icons.alternate_email,
                ),
                SizedBox(height: 16.h),
                
                _buildTextField(
                  controller: email,
                  focusNode: email_F,
                  hint: 'Correo electrónico',
                  icon: Icons.mail_outline,
                ),
                SizedBox(height: 16.h),
                
                _buildTextField(
                  controller: bio,
                  focusNode: bio_F,
                  hint: 'Bio (opcional)',
                  icon: Icons.edit_note,
                ),
                SizedBox(height: 16.h),
                
                _buildTextField(
                  controller: password,
                  focusNode: password_F,
                  hint: 'Contraseña',
                  icon: Icons.lock_outline,
                  isPassword: true,
                ),
                SizedBox(height: 16.h),
                
                _buildTextField(
                  controller: passwordConfirme,
                  focusNode: passwordConfirme_F,
                  hint: 'Confirmar contraseña',
                  icon: Icons.lock_outline,
                  isPassword: true,
                ),
                
                SizedBox(height: 32.h),
                
                // Botón de registro
                _buildSignupButton(),
                
                SizedBox(height: 24.h),
                
                // Link a login
                _buildLoginLink(),
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
        obscureText: isPassword,
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
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 16.h,
          ),
        ),
      ),
    );
  }

  Widget _buildSignupButton() {
    return GestureDetector(
      onTap: () async {
        try {
          await Authentication().Signup(
            email: email.text,
            password: password.text,
            passwordConfirme: passwordConfirme.text,
            username: username.text,
            bio: bio.text,
            profile: _imageFile ?? File(''),
          );
          
          dialogBuilder(context, "¡Registro exitoso! Ya puedes iniciar sesión.");
          widget.show();

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
            'Crear cuenta',
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

  Widget _buildLoginLink() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '¿Ya tienes cuenta? ',
            style: TextStyle(
              fontSize: 15.sp,
              color: Colors.grey[600],
              fontWeight: FontWeight.w400,
            ),
          ),
          GestureDetector(
            onTap: widget.show,
            child: Text(
              'Inicia sesión',
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