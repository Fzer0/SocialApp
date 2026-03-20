import 'dart:io';

import 'package:app/data/firebase_service/storage.dart';
import 'package:app/data/model/usermodel.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  final Usermodel user;
  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  File? _profileImage;
  File? _coverImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _usernameController.text = widget.user.username;
    _bioController.text = widget.user.bio;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickCoverImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _coverImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      String profileUrl = widget.user.profile;
      String coverUrl = widget.user.coverImage;

      if (_profileImage != null) {
        profileUrl = (await StorageMetod().uploadImageToStorage(
              'profile',
              _profileImage!,
            )) ??
            profileUrl;
      }

      if (_coverImage != null) {
        coverUrl = (await StorageMetod().uploadImageToStorage(
              'cover',
              _coverImage!,
            )) ??
            coverUrl;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({
        'username': _usernameController.text.trim(),
        'bio': _bioController.text.trim(),
        'profile': profileUrl,
        'coverImage': coverUrl,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar perfil: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.88),
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.h),
        TextField(
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
        ),
      ],
    );
  }

  Widget _buildCoverPreview() {
    final hasLocal = _coverImage != null;
    final hasNetwork = widget.user.coverImage.isNotEmpty;

    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 170.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22.r),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF19114A),
                Color(0xFF070B1F),
                Color(0xFF2A145A),
              ],
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22.r),
            child: hasLocal
                ? Image.file(
                    _coverImage!,
                    fit: BoxFit.cover,
                  )
                : hasNetwork
                    ? CachedNetworkImage(
                        imageUrl: widget.user.coverImage,
                        fit: BoxFit.cover,
                        placeholder: (c, s) => Container(
                          color: Colors.white.withOpacity(0.04),
                        ),
                        errorWidget: (c, s, e) => const SizedBox.shrink(),
                      )
                    : const SizedBox.shrink(),
          ),
        ),
        Positioned(
          right: 12.w,
          bottom: 12.h,
          child: GestureDetector(
            onTap: _pickCoverImage,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: Colors.white.withOpacity(0.14),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.image_outlined, color: Colors.white, size: 16.sp),
                  SizedBox(width: 6.w),
                  Text(
                    'Cambiar fondo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasLocalImage = _profileImage != null;
    final hasNetworkImage = widget.user.profile.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF070B1F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF070B1F),
        elevation: 0,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          'Editar perfil',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 10.w),
            child: TextButton(
              onPressed: _isLoading ? null : _saveProfile,
              child: _isLoading
                  ? SizedBox(
                      width: 18.w,
                      height: 18.h,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Guardar',
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
            children: [
              _buildCoverPreview(),
              SizedBox(height: 18.h),
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 110.w,
                    height: 110.h,
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF5B5CFF),
                          Color(0xFFD86DFF),
                        ],
                      ),
                    ),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF0D1328),
                      ),
                      child: ClipOval(
                        child: SizedBox(
                          width: 104.w,
                          height: 104.h,
                          child: hasLocalImage
                              ? Image.file(
                                  _profileImage!,
                                  fit: BoxFit.cover,
                                )
                              : hasNetworkImage
                                  ? CachedNetworkImage(
                                      imageUrl: widget.user.profile,
                                      fit: BoxFit.cover,
                                      placeholder: (c, s) => Container(
                                        color: Colors.white.withOpacity(0.04),
                                      ),
                                      errorWidget: (c, s, e) => Container(
                                        color: Colors.white.withOpacity(0.04),
                                        child: Icon(
                                          Icons.person,
                                          size: 42.sp,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    )
                                  : Container(
                                      color: Colors.white.withOpacity(0.04),
                                      child: Icon(
                                        Icons.person,
                                        size: 42.sp,
                                        color: Colors.white70,
                                      ),
                                    ),
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _pickProfileImage,
                    child: Container(
                      width: 34.w,
                      height: 34.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF6B63FF),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6B63FF).withOpacity(0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.edit,
                        size: 18.sp,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              Text(
                'Toca la foto para cambiar tu imagen de perfil',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 12.sp,
                ),
              ),
              SizedBox(height: 24.h),
              _buildTextField(
                controller: _usernameController,
                label: 'Nombre de usuario',
                hint: 'Escribe tu nombre de usuario',
              ),
              SizedBox(height: 18.h),
              _buildTextField(
                controller: _bioController,
                label: 'Biografía',
                hint: 'Cuéntale algo a los demás...',
                maxLines: 4,
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: const Color(0xFF6B63FF),
                    disabledBackgroundColor:
                        const Color(0xFF6B63FF).withOpacity(0.55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18.r),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 22.w,
                          height: 22.h,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Guardar cambios',
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