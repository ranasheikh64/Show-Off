import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_theme.dart';
import '../controllers/chat_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../widgets/message_bubble_widget.dart';
import '../widgets/chat_input_widget.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String chatName;

  const ChatDetailScreen({super.key, required this.chatId, required this.chatName});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ChatController _chatCtrl = Get.find<ChatController>();
  final AuthController _authCtrl = Get.find<AuthController>();
  final TextEditingController _msgCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _chatCtrl.loadMessages(widget.chatId);
  }

  void _send() {
    _chatCtrl.sendMessage(widget.chatId, _msgCtrl.text.trim());
    _msgCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.chatName),
        actions: [
          Obx(() {
            final chat = _chatCtrl.chats.firstWhereOrNull((c) => c.id == widget.chatId);
            final otherUser = chat?.users.firstWhereOrNull((u) => u.id != _authCtrl.currentUser.value?.id);
            final isBlocked = otherUser != null && _chatCtrl.blockedUserIds.contains(otherUser.id);
            
            return PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'block') {
                  if (otherUser != null) _chatCtrl.blockUser(otherUser.id);
                } else if (val == 'unblock') {
                  if (otherUser != null) _chatCtrl.unblockUser(otherUser.id);
                } else if (val == 'timer') {
                  _chatCtrl.setTemporaryTimer(widget.chatId, 60);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Timer set to 60s')));
                }
              },
              itemBuilder: (context) => [
                if (isBlocked)
                  const PopupMenuItem(value: 'unblock', child: Text('Unblock User', style: TextStyle(color: Colors.green)))
                else
                  const PopupMenuItem(value: 'block', child: Text('Block User', style: TextStyle(color: Colors.red))),
                const PopupMenuItem(value: 'timer', child: Text('Disappearing Messages')),
              ],
            );
          }),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (_chatCtrl.currentMessages.isEmpty) {
                return Center(child: Text('Say hi!', style: TextStyle(color: Colors.grey, fontSize: 16.sp)));
              }
              return ListView.builder(
                reverse: true, // Show latest at bottom
                padding: EdgeInsets.all(16.w),
                itemCount: _chatCtrl.currentMessages.length,
                itemBuilder: (context, index) {
                  final msg = _chatCtrl.currentMessages[index];
                  final isMe = msg.sender?.id == _authCtrl.currentUser.value?.id;
                  return MessageBubbleWidget(
                    content: msg.content, 
                    isMe: isMe,
                    messageId: msg.id,
                  );
                },
              );
            }),
          ),
          Obx(() {
            final chat = _chatCtrl.chats.firstWhereOrNull((c) => c.id == widget.chatId);
            final otherUser = chat?.users.firstWhereOrNull((u) => u.id != _authCtrl.currentUser.value?.id);
            final isBlocked = otherUser != null && _chatCtrl.blockedUserIds.contains(otherUser.id);
            
            if (isBlocked) {
              return Container(
                padding: EdgeInsets.all(16.h),
                color: Colors.grey[200],
                child: Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () {
                      if (otherUser != null) _chatCtrl.unblockUser(otherUser.id);
                    },
                    child: const Text('Unblock User to send messages', style: TextStyle(color: Colors.white)),
                  ),
                ),
              );
            }
            return ChatInputWidget(chatId: widget.chatId);
          }),
        ],
      ),
    );
  }
}
