import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../services/chat_api_service.dart';
import '../services/socket_service.dart';
import '../../../core/utils/encryption_util.dart';

class ChatController extends GetxController {
  final ChatApiService _apiService = ChatApiService();

  var chats = <ChatModel>[].obs;
  var currentMessages = <MessageModel>[].obs;
  var isLoading = false.obs;
  var blockedUserIds = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    SocketService.initSocket();
    _listenToSocketEvents();
    fetchChats();
  }

  void _listenToSocketEvents() {
    SocketService.on('new_message', (data) {
      final msg = MessageModel.fromJson(data);
      currentMessages.insert(0, msg);
      String chatId = data['chat'] is Map ? data['chat']['_id'] : data['chat'];
      _updateChatListLatestMessage(chatId, msg);
    });

    SocketService.on('message_reacted', (data) {
      final index = currentMessages.indexWhere((m) => m.id == data['messageId']);
      if (index != -1) {
        currentMessages[index] = MessageModel.fromJson(data['message']);
      }
    });

    SocketService.on('message_deleted_for_everyone', (data) {
      final index = currentMessages.indexWhere((m) => m.id == data['messageId']);
      if (index != -1) {
        final old = currentMessages[index];
        currentMessages[index] = MessageModel(
          id: old.id, sender: old.sender, content: "This message was deleted",
          readBy: old.readBy, isDeletedForEveryone: true, replyTo: old.replyTo, reactions: old.reactions,
        );
      }
    });
  }

  void _updateChatListLatestMessage(String chatId, MessageModel msg) {
    final index = chats.indexWhere((c) => c.id == chatId);
    if (index != -1) {
      final chat = chats[index];
      chats.removeAt(index);
      chats.insert(0, ChatModel(
        id: chat.id, isGroupChat: chat.isGroupChat, chatName: chat.chatName,
        users: chat.users, latestMessage: msg, mutedBy: chat.mutedBy, pinnedBy: chat.pinnedBy,
      ));
    }
  }

  Future<void> fetchChats() async {
    isLoading.value = true;
    try {
      chats.value = await _apiService.fetchChats();
    } catch (e) {
      print(e);
    } finally {
      isLoading.value = false;
    }
  }

  void loadMessages(String chatId) {
    currentMessages.clear();
    SocketService.joinChat(chatId);
    SocketService.emitWithAck('fetch_messages', {'chatId': chatId, 'page': 1, 'limit': 30}, (data) {
      if (data != null && data['success'] == true) {
        final List msgs = data['messages'] ?? [];
        currentMessages.value = msgs.map((m) => MessageModel.fromJson(m)).toList();
      } else {
        print("Failed to fetch messages: ${data?['message']}");
      }
    });
  }

  void sendMessage(String chatId, String content, {String? replyTo}) {
    if (content.isEmpty) return;
    final encrypted = EncryptionUtil.encrypt(content);
    SocketService.emit('send_message', {
      'chatId': chatId,
      'content': encrypted,
      'replyTo': replyTo,
    });
  }

  Future<void> sendMediaMessage(String chatId, String filePath) async {
    try {
      final url = await _apiService.uploadMedia(filePath);
      final encrypted = EncryptionUtil.encrypt(url); // Encrypting the Cloudinary URL
      SocketService.emit('send_message', {'chatId': chatId, 'content': encrypted});
    } catch (e) {
      print("Media upload failed: $e");
    }
  }

  void reactToMessage(String messageId, String emoji) {
    SocketService.emit('react_to_message', {'messageId': messageId, 'emoji': emoji});
  }

  void deleteMessage(String messageId, bool forEveryone) {
    if (forEveryone) {
      SocketService.emit('delete_message_everyone', {'messageId': messageId});
    } else {
      SocketService.emit('delete_message_me', {'messageId': messageId});
      currentMessages.removeWhere((m) => m.id == messageId);
    }
  }

  List<MessageModel> searchLocalMessages(String query) {
    if (query.isEmpty) return currentMessages;
    final q = query.toLowerCase();
    return currentMessages.where((m) => m.content.toLowerCase().contains(q)).toList();
  }

  // --- Phase 7: Privacy, Security & Filters --- //
  
  void blockUser(String userId) {
    SocketService.emitWithAck('block_user', {'blockedId': userId}, (res) {
      if (res != null && res['success'] == true) {
        blockedUserIds.add(userId);
        Get.snackbar('Blocked', 'User blocked successfully', backgroundColor: Colors.red, colorText: Colors.white);
      }
    });
  }

  void unblockUser(String userId) {
    SocketService.emitWithAck('unblock_user', {'blockedId': userId}, (res) {
      if (res != null && res['success'] == true) {
        blockedUserIds.remove(userId);
        Get.snackbar('Unblocked', 'User unblocked successfully', backgroundColor: Colors.green, colorText: Colors.white);
      }
    });
  }

  void lockChat(String chatId, String password) {
    SocketService.emit('lock_chat', {'chatId': chatId, 'password': password});
  }

  void setTemporaryTimer(String chatId, int seconds) {
    SocketService.emit('set_temporary_timer', {'chatId': chatId, 'timer': seconds});
  }

  void toggleChatAction(String chatId, String action) {
    // action: 'pin', 'favourite', 'archive', 'mute'
    SocketService.emit('toggle_chat_action', {'chatId': chatId, 'action': action});
  }

  void deleteChat(String chatId) {
    SocketService.emit('delete_chat', {'chatId': chatId});
    chats.removeWhere((c) => c.id == chatId);
  }

  void clearHistory(String chatId) {
    SocketService.emit('clear_history', {'chatId': chatId});
    currentMessages.clear();
  }

  @override
  void onClose() {
    SocketService.disconnect();
    super.onClose();
  }
}
