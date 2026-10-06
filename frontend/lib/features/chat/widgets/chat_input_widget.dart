import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_theme.dart';
import '../controllers/chat_controller.dart';

class ChatInputWidget extends StatefulWidget {
  final String chatId;
  const ChatInputWidget({super.key, required this.chatId});

  @override
  State<ChatInputWidget> createState() => _ChatInputWidgetState();
}

class _ChatInputWidgetState extends State<ChatInputWidget> {
  final ChatController _chatCtrl = Get.find<ChatController>();
  final TextEditingController _msgCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  void _send() {
    _chatCtrl.sendMessage(widget.chatId, _msgCtrl.text.trim());
    _msgCtrl.clear();
  }

  void _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _chatCtrl.sendMediaMessage(widget.chatId, image.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.attach_file, color: AppTheme.primaryBlue, size: 24.w),
            onPressed: _pickImage,
          ),
          Expanded(
            child: TextField(
              controller: _msgCtrl,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24.r), borderSide: BorderSide.none),
                filled: true,
                fillColor: AppTheme.background,
                contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          CircleAvatar(
            backgroundColor: AppTheme.primaryBlue,
            radius: 24.r,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: _send,
            ),
          ),
        ],
      ),
    );
  }
}
