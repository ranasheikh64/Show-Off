class UserModel {
  final String id;
  final String name;
  final String username;
  final String email;
  final String? profileImage;
  final String? gender;
  final int? age;
  final String? education;
  final String? petLover;
  final List<String> passion;
  final List<String> preferences;
  final bool isBlocked;
  final bool isBlockedBy;
  final bool isOnline;
  final DateTime? lastActive;

  final int postsCount;
  final int lovedByCount;
  final int matchedCount;

  UserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    this.profileImage,
    this.gender,
    this.age,
    this.education,
    this.petLover,
    this.passion = const [],
    this.preferences = const [],
    this.isBlocked = false,
    this.isBlockedBy = false,
    this.isOnline = false,
    this.lastActive,
    this.postsCount = 0,
    this.lovedByCount = 0,
    this.matchedCount = 0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      profileImage: json['profileImage'],
      gender: json['gender'],
      age: json['age'],
      education: json['education'],
      petLover: json['petLover'],
      passion: json['passion'] != null ? List<String>.from(json['passion']) : [],
      preferences: json['preferences'] != null ? List<String>.from(json['preferences']) : [],
      isBlocked: json['isBlocked'] ?? false,
      isBlockedBy: json['isBlockedBy'] ?? false,
      isOnline: json['isOnline'] ?? false,
      lastActive: json['lastActive'] != null ? DateTime.parse(json['lastActive']) : null,
      postsCount: json['postsCount'] ?? 0,
      lovedByCount: json['lovedByCount'] ?? 0,
      matchedCount: json['matchedCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'username': username,
      'email': email,
      'profileImage': profileImage,
      'gender': gender,
      'age': age,
      'education': education,
      'petLover': petLover,
      'passion': passion,
      'preferences': preferences,
      'isBlocked': isBlocked,
      'isBlockedBy': isBlockedBy,
      'isOnline': isOnline,
      'lastActive': lastActive?.toIso8601String(),
      'postsCount': postsCount,
      'lovedByCount': lovedByCount,
      'matchedCount': matchedCount,
    };
  }
}

