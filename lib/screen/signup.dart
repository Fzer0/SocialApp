import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:app/data/firebase_service/firebase_auth.dart';
import 'package:app/screen/login_screen.dart';
import 'package:app/util/dialog.dart';
import 'package:app/util/exeption.dart';
import 'package:app/util/imagepicker.dart';

Padding Textfild(TextEditingController controll, FocusNode focusNode,
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
        decoration: InputDecoration(
          hintText: typename,
          prefixIcon: Icon(
            icon,
            color: focusNode.hasFocus ? Colors.black : Colors.grey[600],
          ),
          contentPadding:
              EdgeInsets.symmetric(horizontal: 15.w, vertical: 15.h),
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

  // 1. Declarar la variable _imageFile aquí, en el estado.
  // Es importante que esté fuera de la función build para que persista.
  File? _imageFile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center, // Centrar el CircleAvatar
            children: [
              SizedBox(width: 96.w, height: 70.h),
              InkWell(
                onTap: () async {
                  // 2. Usar la variable de estado para guardar la imagen.
                  File? pickedImage = await ImagePickerr().uploadImage('gallery');
                  if (pickedImage != null) {
                    setState(() {
                      _imageFile = pickedImage;
                    });
                  }
                },
                child: CircleAvatar(
                  radius: 36.r,
                  backgroundColor: Colors.grey,
                  child: _imageFile == null
                      ? CircleAvatar(
                          radius: 34.r,
                          backgroundImage: AssetImage('images/person.png'),
                          backgroundColor: Colors.grey.shade200,
                        )
                      : CircleAvatar(
                          radius: 34.r,
                          backgroundImage: Image.file(
                            _imageFile!,
                            fit: BoxFit.cover,
                          ).image,
                          backgroundColor: Colors.grey.shade200,
                        ),
                ),
              ),
              SizedBox(height: 50.h),
              // Se usa el widget personalizado Textfild con los argumentos correctos
              Textfild(email, email_F, 'Email', Icons.email),
              SizedBox(height: 15.h),
              Textfild(username, username_F, 'username', Icons.person),
              SizedBox(height: 15.h),
              Textfild(bio, bio_F, 'bio', Icons.abc),
              SizedBox(height: 15.h),
              Textfild(password, password_F, 'Password', Icons.lock),
              SizedBox(height: 15.h),
              Textfild(passwordConfirme, passwordConfirme_F, 'PasswordConfirme', Icons.lock),
              SizedBox(height: 20.h),
              Signup(), // Usar el widget Signup correcto
              SizedBox(height: 15.h),
              Have()
            ],
          ),
        ),
      ),
    );
  }

  Widget Have() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            "Don't you have an account?  ", // Corrección de la gramática
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey,
            ),
          ),
          GestureDetector(
            onTap: widget.show,
            child: Text(
              "Login ",
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

  Widget Signup() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: InkWell(
        onTap: () async {
          try {
            await Authentication().Signup(
              email: email.text,
              password: password.text,
              passwordConfirme: passwordConfirme.text,
              username: username.text,
              bio: bio.text,
              // 3. Pasar _imageFile, que ahora es una variable de estado
              profile: _imageFile ?? File(''),// No necesita el operador ?? File('')
            );
          } on exceptions catch (e) {
            dialogBuilder(context, e.massage);
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
            'Sign up',
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

  Widget Login() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: Container(
        alignment: Alignment.center,
        width: double.infinity,
        height: 44.h,
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(5.r),
        ),
        child: Text(
          "Sign up",
          style: TextStyle(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget Forgot() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15.w),
      child: Text(
        "Forgot your Password?",
        style: TextStyle(
            fontSize: 13.sp,
            color: Colors.grey,
            fontWeight: FontWeight.bold),
      ),
    );
  }
}