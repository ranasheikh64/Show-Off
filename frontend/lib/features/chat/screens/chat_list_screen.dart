import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_theme.dart';
import '../controllers/chat_controller.dart';
import '../models/chat_model.dart';
import '../../auth/controllers/auth_controller.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatController _chatCtrl = Get.put(ChatController());
  final AuthController _authCtrl = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () => _authCtrl.logout(context),
          ),
        ],
      ),
      body: Obx(() {
        if (_chatCtrl.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_chatCtrl.chats.isEmpty) {
          return Center(child: Text('No chats yet', style: TextStyle(fontSize: 16.sp, color: Colors.grey)));
        }
        return ListView.separated(
          itemCount: _chatCtrl.chats.length,
          separatorBuilder: (c, i) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final chat = _chatCtrl.chats[index];
            return _buildChatTile(chat);
          },
        );
      }),
    );
  }

  Widget _buildChatTile(ChatModel chat) {
    final otherUser = chat.isGroupChat 
        ? null 
        : chat.users.firstWhereOrNull((u) => u.id != _authCtrl.currentUser.value?.id);
    
    final name = chat.isGroupChat ? (chat.chatName ?? 'Group') : (otherUser?.name ?? 'Unknown');
    final msg = chat.latestMessage?.content ?? 'No messages yet';

    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      leading: CircleAvatar(
        radius: 24.r,
        backgroundColor: AppTheme.lightBlue,
        child: Text(name[0].toUpperCase(), style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
      ),
      title: Text(name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16.sp)),
      subtitle: Text(msg, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppTheme.textSecondary, fontSize: 14.sp)),
      trailing: chat.unreadCount > 0
          ? Container(
              padding: EdgeInsets.all(6.w),
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: Text(
                chat.unreadCount.toString(),
                style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold),
              ),
            )
          : null,
      onTap: () {
        context.push('/chat/${chat.id}', extra: name);
      },
    );
  }
}
