import 'package:flutter/material.dart';
import 'package:frontend/core/storage/hive_service.dart';
import 'package:frontend/features/auth/models/user_model.dart';

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

  var chatPage = 1.obs;
  var hasMoreChats = true.obs;
  var isFetchingMoreChats = false.obs;
  var searchQuery = ''.obs;
  var searchDebounceTimer; // Optional, or just use Rx worker

  var currentPage = 1.obs;
  var isFetchingMore = false.obs;
  var hasMoreMessages = true.obs;
  var isInitialLoading = false.obs;
  String? currentChatPassword;

  var activeChatId = ''.obs; // Tracks the currently opened chat
  var highlightedMessageId =
      RxnString(); // Tracks a temporarily highlighted message
  var scrollToMessageIndex = (-1).obs;
  var replyToMessage = Rxn<MessageModel>();

  /// Number of chats (people) that have at least one unread message.
  int get unreadChatCount => chats.where((c) => c.unreadCount > 0).length;

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
          debugPrint(
            '[Disappearing Messages] Message ${m.id} expired and removed from UI',
          );
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

  final Set<String> _processedMessageIds = {};

  void _listenToSocketEvents() {
    SocketService.on('new_message', (data) {
      final msg = MessageModel.fromJson(data);
      if (_processedMessageIds.contains(msg.id)) return;
      _processedMessageIds.add(msg.id);
      if (_processedMessageIds.length > 500) _processedMessageIds.clear();

      String chatId = data['chat'] is Map ? data['chat']['_id'] : data['chat'];
      
      try {
        HiveService.saveSingleMessageLocal(chatId, Map<String, dynamic>.from(data));
      } catch(e) {
        print("Failed to save single msg to local storage: $e");
      }

      final myId = Get.find<AuthController>().currentUser.value?.id;
      final isMe = msg.sender?.id == myId;

      if (!isMe) {
        if (activeChatId.value == chatId) {
          // If I am in the chat, mark as read
          SocketService.emit('mark_as_read', {
            'messageId': msg.id,
            'chatId': chatId,
          });
        } else {
          // If I am not in the chat, mark as delivered
          SocketService.emit('mark_as_delivered', {
            'messageId': msg.id,
            'chatId': chatId,
          });
        }
      }

      if (activeChatId.value == chatId) {
        currentMessages.insert(0, msg);
      }

      _updateChatListLatestMessage(chatId, msg, isNewMessage: true);
    });

    SocketService.on('message_seen', (data) {
      final String msgId = data['_id'] ?? data['id'];
      final index = currentMessages.indexWhere((m) => m.id == msgId);
      if (index != -1) {
        currentMessages[index] = MessageModel.fromJson(data);
      }
      String chatId = data['chat'] is Map ? data['chat']['_id'] : data['chat'];
      _updateChatListLatestMessage(chatId, MessageModel.fromJson(data));
    });

    SocketService.on('message_delivered', (data) {
      final String msgId = data['_id'] ?? data['id'];
      final index = currentMessages.indexWhere((m) => m.id == msgId);
      if (index != -1) {
        currentMessages[index] = MessageModel.fromJson(data);
      }
      String chatId = data['chat'] is Map ? data['chat']['_id'] : data['chat'];
      _updateChatListLatestMessage(chatId, MessageModel.fromJson(data));
    });

    SocketService.on('message_reacted', (data) {
      final String msgId = data['_id'] ?? data['id'];
      final index = currentMessages.indexWhere((m) => m.id == msgId);
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

    SocketService.on('user_status_changed', (data) {
      final String userId = data['userId'];
      final bool isOnline = data['isOnline'] ?? false;
      final DateTime? lastActive = data['lastActive'] != null
          ? DateTime.parse(data['lastActive'])
          : null;

      final currentChats = List<ChatModel>.from(chats);
      bool updated = false;

      for (int i = 0; i < currentChats.length; i++) {
        final chat = currentChats[i];
        final userIndex = chat.users.indexWhere((u) => u.id == userId);
        if (userIndex != -1) {
          final updatedUsers = List<UserModel>.from(chat.users);
          final u = updatedUsers[userIndex];
          updatedUsers[userIndex] = UserModel(
            id: u.id,
            name: u.name,
            username: u.username,
            email: u.email,
            profileImage: u.profileImage,
            gender: u.gender,
            age: u.age,
            isBlocked: u.isBlocked,
            isBlockedBy: u.isBlockedBy,
            isOnline: isOnline,
            lastActive: lastActive,
          );
          currentChats[i] = chat.copyWith(users: updatedUsers);
          updated = true;
        }
      }

      if (updated) {
        chats.value = currentChats;
      }
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
        debugPrint(
          '[Disappearing Messages] Updating chat model for $chatId. seconds=$seconds, setBy=$setBy',
        );
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

  void _updateChatListLatestMessage(String chatId, MessageModel msg, {bool isNewMessage = false}) {
    final index = chats.indexWhere((c) => c.id == chatId);
    if (index != -1) {
      final chat = chats[index];
      chats.removeAt(index);

      int newUnreadCount = chat.unreadCount;
      if (isNewMessage) {
        final isMe =
            msg.sender?.id == Get.find<AuthController>().currentUser.value?.id;
        if (activeChatId.value != chatId && !isMe) {
          newUnreadCount++;
        }
      }

      chats.insert(
        0,
        chat.copyWith(latestMessage: msg, unreadCount: newUnreadCount),
      );
    }
  }

  Future<void> fetchChats({bool loadMore = false}) async {
    if (loadMore) {
      if (!hasMoreChats.value || isFetchingMoreChats.value) return;
      isFetchingMoreChats.value = true;
      chatPage.value++;
    } else {
      isLoading.value = true;
      chatPage.value = 1;
      hasMoreChats.value = true;
    }

    try {
      final result = await _apiService.fetchChats(
        page: chatPage.value,
        limit: 20,
        searchQuery: searchQuery.value,
      );
      
      final fetchedChats = result['chats'] as List<ChatModel>;
      hasMoreChats.value = result['hasMore'];

      if (loadMore) {
        final currentList = List<ChatModel>.from(chats);
        // Avoid duplicates just in case
        final existingIds = currentList.map((e) => e.id).toSet();
        for (var c in fetchedChats) {
          if (!existingIds.contains(c.id)) {
            currentList.add(c);
          }
        }
        _sortChats(currentList);
      } else {
        _sortChats(fetchedChats);
      }
      
      // Globally join all chat rooms so we receive new_message everywhere
      for (var chat in chats) {
        SocketService.joinChat(chat.id);
      }
    } catch (e) {
      print(e);
    } finally {
      if (loadMore) {
        isFetchingMoreChats.value = false;
      } else {
        isLoading.value = false;
      }
    }
  }

  void onSearchQueryChanged(String query) {
    searchQuery.value = query;
    // Debounce is ideal here, we can simply call fetchChats directly if typing stops
    // We can use Get.find or simple Timer
    // For simplicity, we just fetch immediately or you can add a debounce package later
    fetchChats();
  }

  void _sortChats(List<ChatModel> list) {
    list.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      if (a.isPinned && b.isPinned) {
        return a.pinOrder.compareTo(b.pinOrder);
      }
      return 0;
    });
    chats.value = list;
  }

  void togglePinChat(String chatId) {
    SocketService.emit('toggle_chat_action', {
      'chatId': chatId,
      'action': 'pin',
    });
    final idx = chats.indexWhere((c) => c.id == chatId);
    if (idx != -1) {
      final chat = chats[idx];
      chats[idx] = chat.copyWith(
        isPinned: !chat.isPinned,
        pinOrder: chat.isPinned ? 999999 : -1,
      );
      _sortChats(List<ChatModel>.from(chats));
    }
  }

  void reorderPinnedChats(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final List<ChatModel> pinned = chats.where((c) => c.isPinned).toList();
    if (oldIndex >= pinned.length || newIndex >= pinned.length) return;

    final ChatModel item = pinned.removeAt(oldIndex);
    pinned.insert(newIndex, item);

    for (int i = 0; i < pinned.length; i++) {
      final idx = chats.indexWhere((c) => c.id == pinned[i].id);
      if (idx != -1) chats[idx] = chats[idx].copyWith(pinOrder: i);
    }

    _sortChats(List<ChatModel>.from(chats));

    final chatIds = pinned.map((c) => c.id).toList();
    SocketService.emit('reorder_pinned_chats', {'chatIds': chatIds});
  }

  void muteChat(String chatId, int? durationInHours) {
    SocketService.emit('mute_chat', {
      'chatId': chatId,
      'durationInHours': durationInHours,
    });
    fetchChats();
  }

  void deleteChat(String chatId) {
    SocketService.emit('delete_chat', {'chatId': chatId});
    chats.removeWhere((c) => c.id == chatId);
  }

  void clearHistory(String chatId) {
    SocketService.emit('clear_history', {'chatId': chatId});
    final idx = chats.indexWhere((c) => c.id == chatId);
    if (idx != -1) {
      chats[idx] = chats[idx].copyWith(latestMessage: null);
      chats.refresh();
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
          
          final parsedMsgs = msgs.map((m) => MessageModel.fromJson(m)).toList();
          currentMessages.value = parsedMsgs;
          
          // Save locally for search
          try {
            HiveService.saveMessagesLocal(chatId, msgs.cast<Map<String, dynamic>>());
          } catch(e) {
            print("Failed to save to local storage: $e");
          }

          // Mark unread messages as read
          final myId = Get.find<AuthController>().currentUser.value?.id;
          for (var msg in currentMessages) {
            if (msg.sender?.id != myId && !msg.readBy.contains(myId)) {
              SocketService.emit('mark_as_read', {
                'messageId': msg.id,
                'chatId': chatId,
              });
            }
          }
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
          
          try {
            HiveService.saveMessagesLocal(chatId, msgs.cast<Map<String, dynamic>>());
          } catch(e) {
            print("Failed to save local msgs: $e");
          }
          
          final newMessages = msgs.map((m) => MessageModel.fromJson(m)).toList();
          final existingIds = currentMessages.map((m) => m.id).toSet();
          
          for (var msg in newMessages) {
            if (!existingIds.contains(msg.id)) {
              currentMessages.add(msg);
            }
          }
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

  Future<void> sendMediaMessage(
    String chatId,
    String filePath, {
    bool isAudio = false, // Keep for backwards compatibility or remove
    String? mediaType, // 'audio', 'image', 'file', 'video'
    int? duration,
  }) async {
    final mType = mediaType ?? (isAudio ? 'audio' : 'image');
    final prefix = '[${mType.toUpperCase()}]';
    
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempContent = '$prefix$filePath';
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

      final finalUrl = '$prefix$url';
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
    debugPrint(
      '[Disappearing Messages] Emitting set_temporary_timer for chat $chatId with $seconds seconds',
    );

    // Optimistic Update
    final index = chats.indexWhere((c) => c.id == chatId);
    if (index != -1) {
      chats[index] = chats[index].copyWith(
        disappearingTimer: seconds,
        disappearingTimerSetBy:
            Get.find<AuthController>().currentUser.value?.id,
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

  // void deleteChat(String chatId) {
  //   SocketService.emit('delete_chat', {'chatId': chatId});
  //   chats.removeWhere((c) => c.id == chatId);
  // }

  // void clearHistory(String chatId) {
  //   SocketService.emit('clear_history', {'chatId': chatId});
  //   currentMessages.clear();
  // }
}
