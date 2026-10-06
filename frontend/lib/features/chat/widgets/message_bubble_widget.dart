import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_theme.dart';
import '../controllers/chat_controller.dart';

class MessageBubbleWidget extends StatelessWidget {
  final String content;
  final bool isMe;
  final String? messageId;

  const MessageBubbleWidget({
    super.key,
    required this.content,
    required this.isMe,
    this.messageId,
  });

  void _showOptions(BuildContext context) {
    if (messageId == null) return;
    final chatCtrl = Get.find<ChatController>();
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.favorite, color: Colors.red),
                title: const Text('React ❤️'),
                onTap: () {
                  chatCtrl.reactToMessage(messageId!, '❤️');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.reply, color: Colors.blue),
                title: const Text('Reply'),
                onTap: () {
                  // Usually sets some state for the input box, just logging for now
                  Navigator.pop(context);
                },
              ),
              if (isMe)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Delete'),
                  onTap: () {
                    chatCtrl.deleteMessage(messageId!, true);
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // If it's a media URL, just show a placeholder or icon for now
    final isMedia = content.startsWith('http');
    
    return GestureDetector(
      onLongPress: () => _showOptions(context),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.only(bottom: 12.h, left: isMe ? 50.w : 0, right: isMe ? 0 : 50.w),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: isMe ? AppTheme.primaryBlue : AppTheme.lightBlue,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16.r),
              topRight: Radius.circular(16.r),
              bottomLeft: isMe ? Radius.circular(16.r) : Radius.circular(0),
              bottomRight: isMe ? Radius.circular(0) : Radius.circular(16.r),
            ),
          ),
          child: isMedia
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.image, color: isMe ? Colors.white : AppTheme.textPrimary),
                    SizedBox(width: 8.w),
                    Text("Media attached", style: TextStyle(color: isMe ? Colors.white : AppTheme.textPrimary)),
                  ],
                )
              : Text(
                  content,
                  style: TextStyle(
                    color: isMe ? Colors.white : AppTheme.textPrimary,
                    fontSize: 15.sp,
                  ),
                ),
        ),
      ),
    );
  }
}
