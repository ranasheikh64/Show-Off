import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/showoff_model.dart';
import 'showoff_image_carousel.dart';

class ShowOffPostCard extends StatelessWidget {
  final ShowOffModel post;
  final bool isMine;
  final VoidCallback onChoose;
  final VoidCallback onMessage;
  final VoidCallback onDelete;

  const ShowOffPostCard({
    super.key,
    required this.post,
    required this.isMine,
    required this.onChoose,
    required this.onMessage,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Stack(
            children: [
              ShowOffImageCarousel(
                images: post.images,
                overlay: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _userInfo(),
                    if (!isMine) ...[SizedBox(height: 14.h), _actions()],
                  ],
                ),
              ),
              if (isMine)
                Positioned(top: 12.h, left: 12.w, child: _deleteButton()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _userInfo() {
    final user = post.user;
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (user?.profileImage != null) ...[
                CircleAvatar(
                  radius: 16.r,
                  backgroundImage: NetworkImage(user!.profileImage!),
                ),
                SizedBox(width: 8.w),
              ],
              Expanded(
                child: Text(
                  user?.name ?? 'Unknown',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                    shadows: const [Shadow(color: Colors.black54, blurRadius: 6)],
                  ),
                ),
              ),
              if (user?.age != null)
                Text(
                  '${user!.age}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    shadows: const [Shadow(color: Colors.black54, blurRadius: 6)],
                  ),
                ),
            ],
          ),
          if (user?.passion != null && user!.passion.isNotEmpty) ...[
            SizedBox(height: 6.h),
            Text(
              user.passion.take(3).join(' • '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 13.sp,
                shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
              ),
            ),
          ],
          if (user?.preferences != null && user!.preferences.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(
              'Looking for: ${user.preferences.take(2).join(', ')}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12.sp,
                shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _deleteButton() => Material(
    color: Colors.black54,
    shape: const CircleBorder(),
    child: IconButton(
      icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      onPressed: onDelete,
    ),
  );

  Widget _actions() => Row(
    children: [
      Expanded(
        child: _button(
          post.isChosen ? 'Loved' : 'Show Love',
          post.isChosen ? Icons.check_circle_rounded : Icons.favorite_rounded,
          onChoose,
          gradient: post.isChosen
              ? const [Color(0xFF8E9AAF), Color(0xFFB8C0CC)]
              : const [Color(0xFFFF4D8D), Color(0xFFFF7A59)],
        ),
      ),
      SizedBox(width: 12.w),
      Expanded(
        child: _button(
          'Message',
          Icons.chat_bubble_rounded,
          onMessage,
          gradient: const [Color(0xFF007BFF), Color(0xFF5AA9FF)],
        ),
      ),
    ],
  );

  Widget _button(
    String label,
    IconData icon,
    VoidCallback onTap, {
    required List<Color> gradient,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28.r),
        child: Ink(
          padding: EdgeInsets.symmetric(vertical: 13.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradient),
            borderRadius: BorderRadius.circular(28.r),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withOpacity(0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18.sp),
              SizedBox(width: 8.w),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
