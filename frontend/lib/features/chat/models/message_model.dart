import '../../auth/models/user_model.dart';
import '../../../core/utils/encryption_util.dart';

class MessageModel {
  final String id;
  final UserModel? sender;
  final String content;
  final List<String> readBy;
  final List<String> deliveredTo;
  final bool isDeletedForEveryone;

  final MessageModel? replyTo;
  final List<dynamic> reactions;
  
  final bool isUploading;
  final double uploadProgress;
  final bool isLocalFile;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final bool isSystemMessage;
  final int? duration;

  MessageModel({
    required this.id,
    this.sender,
    required this.content,
    this.readBy = const [],
    this.deliveredTo = const [],
    this.isDeletedForEveryone = false,
    this.replyTo,
    this.reactions = const [],
    this.isUploading = false,
    this.uploadProgress = 0.0,
    this.isLocalFile = false,
    this.createdAt,
    this.expiresAt,
    this.isSystemMessage = false,
    this.duration,
  });

  MessageModel copyWith({
    String? id,
    UserModel? sender,
    String? content,
    List<String>? readBy,
    List<String>? deliveredTo,
    bool? isDeletedForEveryone,
    MessageModel? replyTo,
    List<dynamic>? reactions,
    bool? isUploading,
    double? uploadProgress,
    bool? isLocalFile,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isSystemMessage,
    int? duration,
  }) {
    return MessageModel(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      content: content ?? this.content,
      readBy: readBy ?? this.readBy,
      deliveredTo: deliveredTo ?? this.deliveredTo,
      isDeletedForEveryone: isDeletedForEveryone ?? this.isDeletedForEveryone,
      replyTo: replyTo ?? this.replyTo,
      reactions: reactions ?? this.reactions,
      isUploading: isUploading ?? this.isUploading,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      isLocalFile: isLocalFile ?? this.isLocalFile,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isSystemMessage: isSystemMessage ?? this.isSystemMessage,
      duration: duration ?? this.duration,
    );
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    String rawContent = json['content'] ?? '';
    bool isDeleted = json['isDeletedForEveryone'] ?? false;
    bool isSystemMessage = json['isSystemMessage'] ?? false;
    
    // Decrypt content if it's not a deleted message or system message
    String decryptedContent;
    if (isDeleted || isSystemMessage) {
      decryptedContent = rawContent;
    } else {
      decryptedContent = EncryptionUtil.decrypt(rawContent);
    }

    return MessageModel(
      id: json['_id'] ?? '',
      sender: (json['sender'] is Map<String, dynamic>) 
          ? UserModel.fromJson(json['sender']) 
          : null,
      content: decryptedContent,
      readBy: List<String>.from(json['readBy']?.map((x) => x is Map ? (x['_id'] ?? '') : x.toString()) ?? []),
      deliveredTo: List<String>.from(json['deliveredTo']?.map((x) => x is Map ? (x['_id'] ?? '') : x.toString()) ?? []),
      isDeletedForEveryone: isDeleted,
      replyTo: (json['replyTo'] is Map<String, dynamic>) 
          ? MessageModel.fromJson(json['replyTo']) 
          : null,
      reactions: json['reactions'] ?? [],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
      isSystemMessage: json['isSystemMessage'] ?? false,
      duration: json['duration'],
    );
  }
}
