import '../../auth/models/user_model.dart';
import '../../../core/utils/encryption_util.dart';

class MessageModel {
  final String id;
  final UserModel? sender;
  final String content;
  final List<String> readBy;
  final bool isDeletedForEveryone;

  final String? replyTo;
  final List<dynamic> reactions;

  MessageModel({
    required this.id,
    this.sender,
    required this.content,
    this.readBy = const [],
    this.isDeletedForEveryone = false,
    this.replyTo,
    this.reactions = const [],
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    String rawContent = json['content'] ?? '';
    bool isDeleted = json['isDeletedForEveryone'] ?? false;
    
    // Decrypt content if it's not a deleted message placeholder
    String decryptedContent = isDeleted ? rawContent : EncryptionUtil.decrypt(rawContent);

    return MessageModel(
      id: json['_id'] ?? '',
      sender: json['sender'] != null ? UserModel.fromJson(json['sender']) : null,
      content: decryptedContent,
      readBy: List<String>.from(json['readBy'] ?? []),
      isDeletedForEveryone: isDeleted,
      replyTo: json['replyTo'],
      reactions: json['reactions'] ?? [],
    );
  }
}
