import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ShowOffFabs extends StatelessWidget {
  final VoidCallback onChats;
  final VoidCallback onAddPost;
  final bool visible;
  final int unreadCount;

  const ShowOffFabs({
    super.key,
    required this.onChats,
    required this.onAddPost,
    this.visible = true,
    this.unreadCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: visible ? Offset.zero : const Offset(1.6, 0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 300),
        child: _buildButtons(),
      ),
    );
  }

  Widget _buildButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Badge(
          isLabelVisible: unreadCount > 0,
          label: Text(
            unreadCount > 99 ? '99+' : '$unreadCount',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          backgroundColor: const Color(0xFFFF3B5C),
          offset: const Offset(-2, -2),
          child: FloatingActionButton(
            heroTag: 'chat_list_fab',
            onPressed: onChats,
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF007BFF),
            elevation: 4,
            child: const Icon(Icons.chat_bubble_rounded),
          ),
        ),
        SizedBox(height: 14.h),
        FloatingActionButton.extended(
          heroTag: 'add_post_fab',
          onPressed: onAddPost,
          backgroundColor: const Color(0xFFFF4D8D),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_a_photo_rounded),
          label: const Text(
            'Post',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
