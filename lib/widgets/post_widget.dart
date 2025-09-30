import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PostWidget extends StatelessWidget {
  const PostWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // Alinea todo a la izquierda
      children: [
        // Encabezado de la publicación
        SizedBox(
          width: 375.w,
          height: 54.h,
          child: Center(
            child: ListTile(
              leading: ClipOval(
                child: SizedBox(
                  width: 35.w,
                  height: 35.h,
                  child: Image.asset('images/person.png'),
                ),
              ),
              title: Text(
                'username',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold, // Negrita para el nombre de usuario
                ),
              ),
              subtitle: Text(
                'location',
                style: TextStyle(fontSize: 11.sp),
              ),
              trailing: const Icon(Icons.more_horiz),
            ),
          ),
        ),
        // Imagen principal de la publicación
        SizedBox(
          width: 375.w,
          height: 375.h,
          child: Image.asset('images/post.jpg', fit: BoxFit.cover),
        ),
        // Fila de iconos y acciones
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          child: Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.favorite_outline,
                  size: 25,
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: Image.asset('images/comment.webp', height: 28.h),
              ),
              IconButton(
                onPressed: () {},
                icon: Image.asset('images/send.jpg', height: 28.h),
              ),
            ],
          ),
        ),
        // Conteo de "me gusta"
        Padding(
          padding: EdgeInsets.only(left: 19.w, bottom: 5.h),
          child: Text(
            '0',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        // Descripción de la publicación
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 15.w),
          child: Row(
            children: [
              Text(
                'username' + ', ', // Agregué el espacio
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'capton',
                style: TextStyle(
                  fontSize: 13.sp,
                ),
              ),
            ],
          ),
        ),
        // Formato de fecha
        Padding(
          padding: EdgeInsets.only(left: 15.w, top: 20.h, bottom: 8.h),
          child: Text(
            'dateformat',
            style: TextStyle(fontSize: 11.sp, color: Colors.grey),
          ),
        ),
      ],
    );
  }
}