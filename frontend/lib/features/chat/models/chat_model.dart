import '../../auth/models/user_model.dart';
import 'message_model.dart';

class ChatModel {
  final String id;
  final bool isGroupChat;
  final String? chatName;
  final List<UserModel> users;
  final MessageModel? latestMessage;
  final List<String> mutedBy;
  final List<String> pinnedBy;
  final List<String> pinnedMessages;
  final bool isLocked;
  final bool isPinned;
  final int pinOrder;
  int disappearingTimer;
  String? disappearingTimerSetBy;
  int unreadCount;

  ChatModel({
    required this.id,
    required this.isGroupChat,
    this.chatName,
    required this.users,
    this.latestMessage,
    this.mutedBy = const [],
    this.pinnedBy = const [],
    this.pinnedMessages = const [],
    this.isLocked = false,
    this.isPinned = false,
    this.pinOrder = 999999,
    this.disappearingTimer = 0,
    this.disappearingTimerSetBy,
    this.unreadCount = 0,
  });

  ChatModel copyWith({
    String? id,
    bool? isGroupChat,
    String? chatName,
    List<UserModel>? users,
    MessageModel? latestMessage,
    List<String>? mutedBy,
    List<String>? pinnedBy,
    List<String>? pinnedMessages,
    bool? isLocked,
    bool? isPinned,
    int? pinOrder,
    int? disappearingTimer,
    String? disappearingTimerSetBy,
    int? unreadCount,
  }) {
    return ChatModel(
      id: id ?? this.id,
      isGroupChat: isGroupChat ?? this.isGroupChat,
      chatName: chatName ?? this.chatName,
      users: users ?? this.users,
      latestMessage: latestMessage ?? this.latestMessage,
      mutedBy: mutedBy ?? this.mutedBy,
      pinnedBy: pinnedBy ?? this.pinnedBy,
      pinnedMessages: pinnedMessages ?? this.pinnedMessages,
      isLocked: isLocked ?? this.isLocked,
      isPinned: isPinned ?? this.isPinned,
      pinOrder: pinOrder ?? this.pinOrder,
      disappearingTimer: disappearingTimer ?? this.disappearingTimer,
      disappearingTimerSetBy: disappearingTimerSetBy ?? this.disappearingTimerSetBy,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['_id'] ?? '',
      isGroupChat: json['isGroupChat'] ?? false,
      chatName: json['chatName'],
      users: (json['users'] as List?)?.map((u) => UserModel.fromJson(u)).toList() ?? [],
      latestMessage: json['latestMessage'] != null ? MessageModel.fromJson(json['latestMessage']) : null,
      mutedBy: (json['mutedBy'] as List?)?.map((e) => e.toString()).toList() ?? [],
      pinnedBy: (json['pinnedBy'] as List?)?.map((e) => e.toString()).toList() ?? [],
      pinnedMessages: (json['pinnedMessages'] as List?)?.map((e) => e.toString()).toList() ?? [],
      isLocked: json['isLocked'] ?? false,
      isPinned: json['isPinned'] ?? false,
      pinOrder: json['pinOrder'] ?? 999999,
      disappearingTimer: json['disappearingTimer'] ?? 0,
      disappearingTimerSetBy: json['disappearingTimerSetBy'],
      unreadCount: json['unreadCount'] ?? 0,
    );
  }
}
