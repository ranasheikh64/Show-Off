import 'package:flutter/material.dart';

import 'dart:async';

import 'package:get/get.dart';

import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../services/chat_api_service.dart';
import '../services/socket_service.dart';
import '../../../core/utils/encryption_util.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../main.dart';

class ChatController extends GetxController {
  final ChatApiService _apiService = ChatApiService();

  var chats = <ChatModel>[].obs;
  var currentMessages = <MessageModel>[].obs;
  var isLoading = false.obs;
  var blockedUserIds = <String>[].obs;

  var currentPage = 1.obs;
  var isFetchingMore = false.obs;
  var hasMoreMessages = true.obs;
  var isInitialLoading = false.obs;
  String? currentChatPassword;
  
  var activeChatId = ''.obs; // Tracks the currently opened chat
  var highlightedMessageId = RxnString(); // Tracks a temporarily highlighted message
  var scrollToMessageIndex = (-1).obs;
  var replyToMessage = Rxn<MessageModel>();

  void highlightMessage(String msgId) {
    highlightedMessageId.value = msgId;
    final index = currentMessages.indexWhere((m) => m.id == msgId);
    if (index != -1) {
      scrollToMessageIndex.value = index;
    }
    Future.delayed(const Duration(seconds: 2), () {
      if (highlightedMessageId.value == msgId) {
        highlightedMessageId.value = null;
      }
    });
  }

  Timer? _disappearingTimer;

  @override
  void onInit() {
    super.onInit();
    SocketService.initSocket();
    _listenToSocketEvents();
    fetchChats();

    _disappearingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (currentMessages.isEmpty) return;
      final now = DateTime.now().toUtc();

      bool removedAny = false;
      final newMessages = currentMessages.where((m) {
        if (m.expiresAt != null && m.expiresAt!.isBefore(now)) {
          debugPrint('[Disappearing Messages] Message ${m.id} expired and removed from UI');
          removedAny = true;
          return false;
        }
        return true;
      }).toList();

      if (removedAny) {
        currentMessages.value = newMessages;
      }
    });
  }

  @override
  void onClose() {
    _disappearingTimer?.cancel();
    SocketService.disconnect();
    super.onClose();
  }

  void _listenToSocketEvents() {
    SocketService.on('new_message', (data) {
      final msg = MessageModel.fromJson(data);
      String chatId = data['chat'] is Map ? data['chat']['_id'] : data['chat'];
      
      if (activeChatId.value == chatId) {
        currentMessages.insert(0, msg);
      }
      
      _updateChatListLatestMessage(chatId, msg);
    });

    SocketService.on('message_reacted', (data) {
      final String msgId = data['_id'] ?? data['id'];
      final index = currentMessages.indexWhere(
        (m) => m.id == msgId,
      );
      if (index != -1) {
        currentMessages[index] = MessageModel.fromJson(data);
      }
    });

    SocketService.on('message_deleted_for_everyone', (data) {
      final index = currentMessages.indexWhere(
        (m) => m.id == data['messageId'],
      );
      if (index != -1) {
        final old = currentMessages[index];
        currentMessages[index] = MessageModel(
          id: old.id,
          sender: old.sender,
          content: "This message was deleted",
          readBy: old.readBy,
          isDeletedForEveryone: true,
          replyTo: old.replyTo,
          reactions: old.reactions,
        );
      }
    });

    SocketService.on('user_blocked', (data) {
      fetchChats();
    });

    SocketService.on('user_unblocked', (data) {
      fetchChats();
    });

    SocketService.on('pinned_messages_updated', (data) {
      // Just refresh chats to get updated pinned messages
      fetchChats();
    });

    SocketService.on('timer_updated', (data) {
      debugPrint('[Disappearing Messages] Received timer_updated event: $data');
      final int seconds = data['seconds'] ?? 0;
      final String chatId = data['chatId'] ?? '';
      final String setBy = data['setBy'] ?? '';

      final index = chats.indexWhere((c) => c.id == chatId);
      if (index != -1) {
        debugPrint('[Disappearing Messages] Updating chat model for $chatId. seconds=$seconds, setBy=$setBy');
        chats[index] = chats[index].copyWith(
          disappearingTimer: seconds,
          disappearingTimerSetBy: seconds > 0 ? setBy : null,
        );
      }

      final msg = seconds == 0
          ? 'Disappearing messages turned off'
          : 'Disappearing messages timer set to ${seconds}s';
      MyApp.scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(msg)),
      );
    });
  }

  void _updateChatListLatestMessage(String chatId, MessageModel msg) {
    final index = chats.indexWhere((c) => c.id == chatId);
    if (index != -1) {
      final chat = chats[index];
      chats.removeAt(index);
      
      // If this is not the active chat, increment unread count
      final isMe = msg.sender?.id == Get.find<AuthController>().currentUser.value?.id;
      final newUnreadCount = (activeChatId.value != chatId && !isMe) ? chat.unreadCount + 1 : chat.unreadCount;
      
      chats.insert(
        0,
        chat.copyWith(
          latestMessage: msg,
          unreadCount: newUnreadCount,
        ),
      );
    }
  }

  Future<void> fetchChats() async {
    isLoading.value = true;
    try {
      chats.value = await _apiService.fetchChats();
      // Globally join all chat rooms so we receive new_message everywhere
      for (var chat in chats) {
        SocketService.joinChat(chat.id);
      }
    } catch (e) {
      print(e);
    } finally {
      isLoading.value = false;
    }
  }

  void loadMessages(
    String chatId, {
    String? password,
    VoidCallback? onUnlockFailed,
  }) {
    activeChatId.value = chatId;
    
    // Reset unread count when opening chat
    final index = chats.indexWhere((c) => c.id == chatId);
    if (index != -1) {
      chats[index] = chats[index].copyWith(unreadCount: 0);
    }
    
    currentMessages.clear();
    currentPage.value = 1;
    hasMoreMessages.value = true;
    isInitialLoading.value = true;
    currentChatPassword = password;

    SocketService.joinChat(chatId);
    SocketService.emitWithAck(
      'fetch_messages',
      {
        'chatId': chatId,
        'page': currentPage.value,
        'limit': 30,
        'password': password,
      },
      (data) {
        isInitialLoading.value = false;
        if (data != null && data['success'] == true) {
          final List msgs = data['messages'] ?? [];
          if (msgs.length < 30) hasMoreMessages.value = false;
          currentMessages.value = msgs
              .map((m) => MessageModel.fromJson(m))
              .toList();
        } else {
          if (data?['message'] == 'Invalid chat password') {
            if (onUnlockFailed != null) {
              onUnlockFailed();
            }
            return;
          }
          MyApp.scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text(data?['message'] ?? 'Failed to fetch messages'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }

  void loadMoreMessages(String chatId) {
    if (isFetchingMore.value ||
        !hasMoreMessages.value ||
        isInitialLoading.value)
      return;
    isFetchingMore.value = true;
    currentPage.value++;

    SocketService.emitWithAck(
      'fetch_messages',
      {
        'chatId': chatId,
        'page': currentPage.value,
        'limit': 30,
        'password': currentChatPassword,
      },
      (data) {
        isFetchingMore.value = false;
        if (data != null && data['success'] == true) {
          final List msgs = data['messages'] ?? [];
          if (msgs.length < 30) hasMoreMessages.value = false;
          currentMessages.addAll(
            msgs.map((m) => MessageModel.fromJson(m)).toList(),
          );
        }
      },
    );
  }


  void setReplyTo(MessageModel? msg) {
    replyToMessage.value = msg;
  }

  void deactivateChat() {
    activeChatId.value = '';
    replyToMessage.value = null;
  }

  void sendMessage(String chatId, String content) {
    if (content.isEmpty) return;
    final encrypted = EncryptionUtil.encrypt(content);
    SocketService.emit('send_message', {
      'chatId': chatId,
      'content': encrypted,
      'replyTo': replyToMessage.value?.id,
    });
    replyToMessage.value = null;
  }

  Future<void> sendMediaMessage(String chatId, String filePath, {bool isAudio = false, int? duration}) async {
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempContent = isAudio ? '[AUDIO]$filePath' : filePath;
    final tempMsg = MessageModel(
      id: tempId,
      sender: Get.find<AuthController>().currentUser.value,
      content: tempContent,
      isLocalFile: true,
      isUploading: true,
      uploadProgress: 0.0,
      createdAt: DateTime.now(),
      duration: duration,
    );
    currentMessages.insert(0, tempMsg);

    try {
      final url = await _apiService.uploadMedia(
        filePath,
        onSendProgress: (count, total) {
          final index = currentMessages.indexWhere((m) => m.id == tempId);
          if (index != -1) {
            currentMessages[index] = currentMessages[index].copyWith(
              uploadProgress: count / total,
            );
          }
        },
      );

      final finalUrl = isAudio ? '[AUDIO]$url' : url;
      final encrypted = EncryptionUtil.encrypt(finalUrl);
      SocketService.emitWithAck(
        'send_message',
        {
          'chatId': chatId, 
          'content': encrypted,
          'duration': duration,
          'replyTo': replyToMessage.value?.id,
        },
        (data) {
          currentMessages.removeWhere((m) => m.id == tempId);
          replyToMessage.value = null;
        },
      );
    } catch (e) {
      print("Media upload failed: $e");
      currentMessages.removeWhere((m) => m.id == tempId);
      MyApp.scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Failed to send media'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void reactToMessage(String messageId, String emoji) {
    if (activeChatId.value.isEmpty) return;
    SocketService.emit('react_to_message', {
      'messageId': messageId,
      'chatId': activeChatId.value,
      'emoji': emoji,
    });
  }

  void deleteMessage(String messageId, bool forEveryone) {
    if (activeChatId.value.isEmpty) return;
    SocketService.emit('delete_message', {
      'messageId': messageId,
      'chatId': activeChatId.value,
      'forEveryone': forEveryone,
    });
    if (!forEveryone) {
      currentMessages.removeWhere((m) => m.id == messageId);
    }
  }

  void togglePinMessage(String messageId) {
    if (activeChatId.value.isEmpty) return;
    SocketService.emit('toggle_pin_message', {
      'chatId': activeChatId.value,
      'messageId': messageId,
    });
  }

  List<MessageModel> searchLocalMessages(String query) {
    if (query.isEmpty) return currentMessages;
    final q = query.toLowerCase();
    return currentMessages
        .where((m) => m.content.toLowerCase().contains(q))
        .toList();
  }

  // --- Phase 7: Privacy, Security & Filters --- //

  void blockUser(String userId) {
    SocketService.emitWithAck('block_user', {'blockedId': userId}, (res) {
      if (res != null && res['success'] == true) {
        blockedUserIds.add(userId);
        MyApp.scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text('User blocked successfully'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  void unblockUser(String userId) {
    SocketService.emitWithAck('unblock_user', {'blockedId': userId}, (res) {
      if (res != null && res['success'] == true) {
        blockedUserIds.remove(userId);
        MyApp.scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text('User unblocked successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  void lockChat(String chatId, String password) {
    SocketService.emitWithAck(
      'lock_chat',
      {'chatId': chatId, 'password': password},
      (data) {
        if (data != null && data['success'] == true) {
          fetchChats();
        }
      },
    );
  }

  void disableChatLock(String chatId) {
    SocketService.emitWithAck('lock_chat', {'chatId': chatId, 'password': ''}, (
      data,
    ) {
      if (data != null && data['success'] == true) {
        fetchChats();
        MyApp.scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text('Chat lock disabled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  void setTemporaryTimer(String chatId, int seconds) {
    debugPrint('[Disappearing Messages] Emitting set_temporary_timer for chat $chatId with $seconds seconds');
    
    // Optimistic Update
    final index = chats.indexWhere((c) => c.id == chatId);
    if (index != -1) {
      chats[index] = chats[index].copyWith(
        disappearingTimer: seconds,
        disappearingTimerSetBy: Get.find<AuthController>().currentUser.value?.id,
      );
    }
    
    SocketService.emit('set_temporary_timer', {
      'chatId': chatId,
      'seconds': seconds,
    });
  }

  void toggleChatAction(String chatId, String action) {
    // action: 'pin', 'favourite', 'archive', 'mute'
    SocketService.emit('toggle_chat_action', {
      'chatId': chatId,
      'action': action,
    });
  }

  void deleteChat(String chatId) {
    SocketService.emit('delete_chat', {'chatId': chatId});
    chats.removeWhere((c) => c.id == chatId);
  }

  void clearHistory(String chatId) {
    SocketService.emit('clear_history', {'chatId': chatId});
    currentMessages.clear();
  }
}
