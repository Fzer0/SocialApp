import 'package:app/data/firebase_service/firestor.dart';
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
    _captionController =
        TextEditingController(text: widget.initialCaption);
    _locationController =
        TextEditingController(text: widget.initialLocation);
  }

  @override
  void dispose() {
    _captionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _showError(Object e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Error al actualizar publicación')),
    );
  }

  Future<void> _saveChanges() async {
    if (_loading) return;

    final caption = _captionController.text.trim();
    final location = _locationController.text.trim();

    if (caption == widget.initialCaption.trim() &&
        location == widget.initialLocation.trim()) {
      Navigator.pop(context);
      return;
    }

    setState(() => _loading = true);

    try {
      await FirebaseFirestor().updatePost(
        postId: widget.postId,
        caption: caption,
        location: location,
      );

      if (!mounted) return;

      Navigator.pop(context, true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Publicación actualizada')),
      );
    } catch (e) {
      _showError(e);
    }

    setState(() => _loading = false);
  }

  InputDecoration _inputDecoration({
    required String hint,
    IconData? icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.white.withOpacity(0.45),
        fontSize: 13.sp,
      ),
      prefixIcon: icon != null
          ? Icon(icon, color: Colors.white.withOpacity(0.6))
          : null,
      filled: true,
      fillColor: Colors.white.withOpacity(0.06),
      contentPadding:
          EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B1F),

      // 🔝 APPBAR estilo HOME
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(88.h),
        child: SafeArea(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: const Color(0xFF070B1F),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(0.04),
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Editar',
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(18.w),
          decoration: BoxDecoration(
            color: const Color(0xFF12172C),
            borderRadius: BorderRadius.circular(24.r),
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
              Text(
                'Actualiza tu publicación',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.white.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 18.h),

              // ✏️ CAPTION
              TextField(
                controller: _captionController,
                maxLines: 5,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(
                  hint: 'Escribe una descripción...',
                  icon: Icons.edit_outlined,
                ),
              ),

              SizedBox(height: 16.h),

              // 📍 LOCATION
              TextField(
                controller: _locationController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(
                  hint: 'Ubicación',
                  icon: Icons.location_on_outlined,
                ),
              ),

              SizedBox(height: 24.h),

              // 🔘 BOTÓN
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton(
                  onPressed: _loading ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: const Color(0xFF5B5CFF),
                    disabledBackgroundColor:
                        const Color(0xFF5B5CFF).withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : Text(
                          'Guardar cambios',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
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