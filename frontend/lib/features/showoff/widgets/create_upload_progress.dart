import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_theme.dart';

class CreateUploadProgress extends StatelessWidget {
  final double progress;

  const CreateUploadProgress({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100.w,
              height: 100.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFF4D8D), AppTheme.primaryBlue],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            SizedBox(height: 28.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(20.r),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8.h,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Uploading your photos...',
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
