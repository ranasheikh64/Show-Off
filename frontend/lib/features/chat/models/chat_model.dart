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

  ChatModel({
    required this.id,
    required this.isGroupChat,
    this.chatName,
    required this.users,
    this.latestMessage,
    this.mutedBy = const [],
    this.pinnedBy = const [],
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['_id'] ?? '',
      isGroupChat: json['isGroupChat'] ?? false,
      chatName: json['chatName'],
      users: (json['users'] as List?)?.map((u) => UserModel.fromJson(u)).toList() ?? [],
      latestMessage: json['latestMessage'] != null ? MessageModel.fromJson(json['latestMessage']) : null,
      mutedBy: List<String>.from(json['mutedBy'] ?? []),
      pinnedBy: List<String>.from(json['pinnedBy'] ?? []),
    );
  }
}
