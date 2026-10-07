import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_theme.dart';

class ShowOffEmptyState extends StatelessWidget {
  final bool isMyPosts;

  const ShowOffEmptyState({super.key, required this.isMyPosts});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(28.w),
              decoration: const BoxDecoration(
                color: AppTheme.lightBlue,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.photo_camera_back_rounded,
                size: 56.sp,
                color: AppTheme.primaryBlue,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              isMyPosts ? 'No posts yet' : 'Nothing to see yet',
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8.h),
            Text(
              isMyPosts
                  ? 'Tap the camera button to share your first photos!'
                  : 'Be the first to Show Off. Tap the camera button to post!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.sp, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
