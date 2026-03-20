import 'dart:io';

import 'package:app/data/firebase_service/firestor.dart';
import 'package:app/data/firebase_service/storage.dart';
import 'package:app/util/upload_bus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path_provider/path_provider.dart';

class AddPostTextScreen extends StatefulWidget {
  final File file;
  const AddPostTextScreen(this.file, {super.key});

  @override
  State<AddPostTextScreen> createState() => _AddPostTextScreenState();
}

class _AddPostTextScreenState extends State<AddPostTextScreen> {
  final TextEditingController caption = TextEditingController();
  final TextEditingController location = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    caption.dispose();
    location.dispose();
    super.dispose();
  }

  Future<void> _sharePost() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      final dir = await getTemporaryDirectory();
      final targetPath =
          '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final XFile? compressedXFile =
          await FlutterImageCompress.compressAndGetFile(
        widget.file.absolute.path,
        targetPath,
        quality: 85,
        format: CompressFormat.jpeg,
      );

      if (compressedXFile == null) {
        throw Exception('Fallo al comprimir la imagen');
      }

      final File finalFile = File(compressedXFile.path);

      final String postUrl =
          await StorageMetod().uploadImageToStorage('posts', finalFile) ?? '';

      if (postUrl.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fallo al subir la imagen')),
        );
        return;
      }

      bool created = false;

      try {
        created = await FirebaseFirestor().CreatePost(
          postImage: postUrl,
          caption: caption.text.trim(),
          location: location.text.trim(),
        );
      } catch (e) {
        created = false;
      }

      if (!mounted) return;

      if (created) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post publicado')),
        );

        try {
          UploadBus.controller.add(postUrl);
        } catch (_) {}

        Navigator.of(context).pop(postUrl);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo crear el post')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fallo al publicar: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.35),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 14.h,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18.r),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.08),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18.r),
          borderSide: const BorderSide(
            color: Color(0xFF6E76FF),
          ),
        ),
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
          'New Post',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 10.w),
            child: TextButton(
              onPressed: isLoading ? null : _sharePost,
              child: isLoading
                  ? SizedBox(
                      width: 18.w,
                      height: 18.h,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Publicar',
                      style: TextStyle(
                        color: const Color(0xFF7B8CFF),
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 24.h),
        child: Container(
          padding: EdgeInsets.all(18.w),
          decoration: BoxDecoration(
            color: const Color(0xFF12172C),
            borderRadius: BorderRadius.circular(28.r),
            border: Border.all(
              color: Colors.white.withOpacity(0.06),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.22),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(22.r),
                child: SizedBox(
                  width: double.infinity,
                  height: 300.h,
                  child: Image.file(
                    widget.file,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: 18.h),
              Text(
                'Descripción',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.88),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8.h),
              _buildInput(
                controller: caption,
                hint: 'Escribe un pie de foto...',
                maxLines: 4,
              ),
              SizedBox(height: 18.h),
              Text(
                'Ubicación',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.88),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8.h),
              _buildInput(
                controller: location,
                hint: 'Agrega una ubicación...',
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _sharePost,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: const Color(0xFF6B63FF),
                    disabledBackgroundColor:
                        const Color(0xFF6B63FF).withOpacity(0.55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18.r),
                    ),
                  ),
                  child: isLoading
                      ? SizedBox(
                          width: 22.w,
                          height: 22.h,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Publicar ahora',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}