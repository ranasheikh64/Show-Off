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
          PopupMenuButton<String>(
            onSelected: (val) {
              if (val == 'block') {
                // For simplicity, blocking the other user in a 1-to-1 chat.
                // Normally you'd extract the other userId from the chat model.
                // Assuming we have it or can get it from ChatController.
                final chat = _chatCtrl.chats.firstWhereOrNull((c) => c.id == widget.chatId);
                final otherUser = chat?.users?.firstWhereOrNull((u) => u.id != _authCtrl.currentUser.value?.id);
                if (otherUser != null) _chatCtrl.blockUser(otherUser.id!);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User Blocked')));
              } else if (val == 'timer') {
                _chatCtrl.setTemporaryTimer(widget.chatId, 60); // e.g. 60 seconds
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Timer set to 60s')));
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'block', child: Text('Block User')),
              const PopupMenuItem(value: 'timer', child: Text('Disappearing Messages')),
            ],
          ),
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
          ChatInputWidget(chatId: widget.chatId),
        ],
      ),
    );
  }
}
