import '../../auth/models/user_model.dart';

class ShowOffModel {
  final String id;
  final UserModel? user;
  final List<String> images;
  final DateTime? createdAt;
  final bool isChosen;

  ShowOffModel({
    required this.id,
    this.user,
    required this.images,
    this.createdAt,
    this.isChosen = false,
  });

  ShowOffModel copyWith({bool? isChosen}) => ShowOffModel(
        id: id,
        user: user,
        images: images,
        createdAt: createdAt,
        isChosen: isChosen ?? this.isChosen,
      );

  factory ShowOffModel.fromJson(Map<String, dynamic> json) {
    return ShowOffModel(
      id: json['_id'] ?? '',
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      images: json['images'] != null ? List<String>.from(json['images']) : [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      isChosen: json['isChosen'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user': user?.toJson(),
      'images': images,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
