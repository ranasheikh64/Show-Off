import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';


class ShowOffEmptyState extends StatelessWidget {
  final bool isMyPosts;
  final bool isFiltering;

  const ShowOffEmptyState({super.key, required this.isMyPosts, this.isFiltering = false});

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
              decoration: BoxDecoration(
                color: const Color(0xFFFF4D8D).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 56.sp,
                color: const Color(0xFFFF4D8D),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              isMyPosts 
                ? 'No posts yet' 
                : isFiltering 
                  ? 'No match found' 
                  : 'Nothing to see yet',
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            SizedBox(height: 8.h),
            Text(
              isMyPosts
                  ? 'Tap the camera button to share your first photos!'
                  : isFiltering 
                    ? 'Try adjusting your search or filters to see more results.'
                    : 'Be the first to Show Off. Tap the camera button to post!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.sp, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
