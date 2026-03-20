import 'package:app/data/firebase_service/firestor.dart';
import 'package:app/util/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EditPostScreen extends StatefulWidget {
  final String postId;
  final String initialCaption;
  final String initialLocation;

  const EditPostScreen({
    super.key,
    required this.postId,
    required this.initialCaption,
    required this.initialLocation,
  });

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  late final TextEditingController _captionController;
  late final TextEditingController _locationController;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _captionController = TextEditingController(text: widget.initialCaption);
    _locationController = TextEditingController(text: widget.initialLocation);
  }

  @override
  void dispose() {
    _captionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _showError(Object e) {
    if (!mounted) return;

    String message = 'Error al actualizar la publicación';
    final errorText = e.toString().toLowerCase();

    if (errorText.contains('permission')) {
      message = 'No tienes permisos para editar esta publicación';
    } else if (errorText.contains('not authenticated')) {
      message = 'Debes iniciar sesión nuevamente';
    } else if (errorText.contains('network')) {
      message = 'Error de red. Revisa tu conexión';
    } else if (errorText.contains('post not found')) {
      message = 'La publicación no existe o fue eliminada';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _saveChanges() async {
    if (_loading) return;

    final caption = _captionController.text.trim();
    final location = _locationController.text.trim();

    if (caption == widget.initialCaption.trim() &&
        location == widget.initialLocation.trim()) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      await FirebaseFirestor().updatePost(
        postId: widget.postId,
        caption: caption,
        location: location,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Publicación actualizada')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null
          ? Icon(
              icon,
              color: AppColors.textSecondary,
              size: 20.sp,
            )
          : null,
      labelStyle: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13.sp,
      ),
      hintStyle: TextStyle(
        color: AppColors.textSecondary.withOpacity(0.7),
        fontSize: 13.sp,
      ),
      filled: true,
      fillColor: AppColors.inputFill,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: BorderSide(
          color: AppColors.textSecondary.withOpacity(0.10),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 1.2,
        ),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Editar publicación',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(18.w),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: AppColors.textSecondary.withOpacity(0.08),
              ),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Actualiza los datos de tu publicación',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 18.h),
                TextField(
                  controller: _captionController,
                  maxLines: 5,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14.sp,
                  ),
                  decoration: _inputDecoration(
                    label: 'Descripción',
                    hint: 'Escribe una descripción para tu publicación',
                    icon: Icons.edit_outlined,
                  ),
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: _locationController,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14.sp,
                  ),
                  decoration: _inputDecoration(
                    label: 'Ubicación',
                    hint: 'Agrega una ubicación',
                    icon: Icons.location_on_outlined,
                  ),
                ),
                SizedBox(height: 24.h),
                SizedBox(
                  width: double.infinity,
                  height: 52.h,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor:
                          AppColors.primary.withOpacity(0.55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    child: _loading
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
                              fontSize: 15.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}