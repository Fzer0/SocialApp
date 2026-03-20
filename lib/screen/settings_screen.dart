import 'package:app/data/firebase_service/firestor.dart';
import 'package:app/data/model/usermodel.dart';
import 'package:app/screen/edit_profile_screen.dart';
import 'package:app/screen/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsScreen extends StatelessWidget {
  final Usermodel user;
  const SettingsScreen({super.key, required this.user});

  Widget _sectionTitle(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h, top: 8.h),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withOpacity(0.50),
          fontSize: 12.sp,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.4,
        ),
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    final color = danger ? const Color(0xFFFF6B7A) : Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18.r),
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: Colors.white.withOpacity(0.06),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38.w,
              height: 38.h,
              decoration: BoxDecoration(
                color: danger
                    ? const Color(0xFFFF6B7A).withOpacity(0.10)
                    : const Color(0xFF4F63FF).withOpacity(0.14),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 4.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.45),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withOpacity(0.35),
              size: 22.sp,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF11162B),
        title: const Text(
          'Cerrar sesión',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '¿Seguro que quieres salir de tu cuenta?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();

              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => WelcomeScreen(
                    onLogin: () {},
                    onSignup: () {},
                  ),
                ),
                (route) => false,
              );
            },
            child: const Text(
              'Salir',
              style: TextStyle(color: Color(0xFFFF6B7A)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteAccountDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF11162B),
        title: const Text(
          'Eliminar cuenta',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Esta acción intentará borrar tu cuenta. Si Firebase pide volver a iniciar sesión, tendrás que entrar otra vez antes de eliminarla.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                await FirebaseFirestor().deleteAccount();

                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => WelcomeScreen(
                      onLogin: () {},
                      onSignup: () {},
                    ),
                  ),
                  (route) => false,
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('No se pudo eliminar la cuenta: $e'),
                  ),
                );
              }
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Color(0xFFFF6B7A)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B1F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF070B1F),
        elevation: 0,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          'Configuración',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('CUENTA'),
            _tile(
              icon: Icons.person_outline,
              title: 'Editar perfil',
              subtitle: 'Foto, fondo, nombre y biografía',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EditProfileScreen(user: user),
                  ),
                );
              },
            ),
            SizedBox(height: 6.h),
            _sectionTitle('SESIÓN'),
            _tile(
              icon: Icons.logout,
              title: 'Cerrar sesión',
              subtitle: 'Salir de tu cuenta actual',
              danger: true,
              onTap: () => _showLogoutDialog(context),
            ),
            _tile(
              icon: Icons.delete_outline,
              title: 'Eliminar cuenta',
              subtitle: 'Borrar tu usuario actual',
              danger: true,
              onTap: () => _showDeleteAccountDialog(context),
            ),
          ],
        ),
      ),
    );
  }
}