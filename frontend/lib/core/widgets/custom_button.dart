import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_theme.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isOutlined;
  final double? width;
  final double? height;
  final Color? color;
  final Gradient? gradient;
  final double? borderRadius;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.width,
    this.height,
    this.color,
    this.gradient,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 50.h,
      child: isOutlined
          ? OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: color ?? AppTheme.primaryBlue, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius ?? 12.r)),
              ),
              child: _buildChild(color ?? AppTheme.primaryBlue),
            )
          : Container(
              decoration: BoxDecoration(
                gradient: gradient ?? LinearGradient(colors: [color ?? AppTheme.primaryBlue, color ?? AppTheme.primaryBlue]),
                borderRadius: BorderRadius.circular(borderRadius ?? 12.r),
                boxShadow: gradient != null ? [
                  BoxShadow(
                    color: gradient!.colors.last.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ] : null,
              ),
              child: ElevatedButton(
                onPressed: isLoading ? null : onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius ?? 12.r)),
                  elevation: 0,
                ),
                child: _buildChild(Colors.white),
              ),
            ),
    );
  }

  Widget _buildChild(Color textColor) {
    if (isLoading) {
      return SizedBox(
        height: 24.w,
        width: 24.w,
        child: CircularProgressIndicator(color: textColor, strokeWidth: 2.5),
      );
    }
    return Text(
      text,
      style: TextStyle(
        color: textColor,
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
