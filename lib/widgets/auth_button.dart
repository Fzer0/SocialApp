import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AuthButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final bool outlined;
  final bool loading;

  const AuthButton({
    super.key,
    required this.text,
    required this.onTap,
    this.outlined = false,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 50.h,
        margin: EdgeInsets.only(bottom: 14.h),
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : const Color(0xFF2979FF),
          borderRadius: BorderRadius.circular(22.r),
          border: outlined
              ? Border.all(color: Colors.white, width: 1.4)
              : null,
          boxShadow: outlined
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFF2979FF).withOpacity(0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Center(
          child: loading
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
                  text,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}