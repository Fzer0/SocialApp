import 'package:app/data/firebase_service/firestor.dart';
import 'package:app/screen/post_detail_screen.dart';
import 'package:app/util/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SavedPostsScreen extends StatelessWidget {
  const SavedPostsScreen({super.key});

  void _openPost(BuildContext context, DocumentSnapshot doc) {
    final rawData = doc.data();
    if (rawData == null || rawData is! Map<String, dynamic>) return;

    final data = rawData;
    final postId = (data['postId'] ?? doc.id).toString();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PostDetailScreen(
          postId: postId,
          postData: data,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          title: const Text('Posts guardados'),
        ),
        body: Center(
          child: Text(
            'Debes iniciar sesión',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text('Posts guardados'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestor().getSavedPosts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error al cargar guardados',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Text(
                'No tienes publicaciones guardadas',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }

          return GridView.builder(
            padding: EdgeInsets.all(12.w),
            itemCount: docs.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final rawData = doc.data();

              if (rawData == null || rawData is! Map<String, dynamic>) {
                return Container(
                  color: AppColors.inputFill,
                  child: const Icon(Icons.broken_image),
                );
              }

              final data = rawData;
              final imageUrl = (data['postImage'] ?? '') as String;

              return GestureDetector(
                onTap: () => _openPost(context, doc),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.r),
                  child: imageUrl.isEmpty
                      ? Container(
                          color: AppColors.inputFill,
                          child: const Icon(Icons.broken_image),
                        )
                      : Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.inputFill,
                            child: const Icon(Icons.broken_image),
                          ),
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}