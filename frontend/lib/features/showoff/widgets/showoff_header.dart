import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_theme.dart';

class ShowOffHeader extends StatelessWidget {
  final bool showMyPosts;
  final ValueChanged<bool> onChanged;

  const ShowOffHeader({
    super.key,
    required this.showMyPosts,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShaderMask(
            shaderCallback: (r) => const LinearGradient(
              colors: [Color(0xFFFF4D8D), AppTheme.primaryBlue],
            ).createShader(r),
            child: Text(
              'Show Off',
              style: TextStyle(
                fontSize: 30.sp,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          Text(
            'Show your best self & find your match',
            style: TextStyle(fontSize: 13.sp, color: AppTheme.textSecondary),
          ),
          SizedBox(height: 14.h),
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              children: [
                _tab(
                  'Explore',
                  Icons.explore_rounded,
                  !showMyPosts,
                  () => onChanged(false),
                ),
                _tab(
                  'My Posts',
                  Icons.photo_library_rounded,
                  showMyPosts,
                  () => onChanged(true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tab(String label, IconData icon, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    colors: [AppTheme.primaryBlue, Color(0xFF5AA9FF)],
                  )
                : null,
            borderRadius: BorderRadius.circular(26.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18.sp,
                color: selected ? Colors.white : AppTheme.textSecondary,
              ),
              SizedBox(width: 6.w),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14.sp,
                  color: selected ? Colors.white : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
