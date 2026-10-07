class UserModel {
  final String id;
  final String name;
  final String username;
  final String email;
  final String? profileImage;
  final String? gender;
  final int? age;
  final bool isBlocked;
  final bool isBlockedBy;
  final bool isOnline;
  final DateTime? lastActive;

  UserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    this.profileImage,
    this.gender,
    this.age,
    this.isBlocked = false,
    this.isBlockedBy = false,
    this.isOnline = false,
    this.lastActive,
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
      isBlocked: json['isBlocked'] ?? false,
      isBlockedBy: json['isBlockedBy'] ?? false,
      isOnline: json['isOnline'] ?? false,
      lastActive: json['lastActive'] != null ? DateTime.parse(json['lastActive']) : null,
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
      'isBlocked': isBlocked,
      'isBlockedBy': isBlockedBy,
      'isOnline': isOnline,
      'lastActive': lastActive?.toIso8601String(),
    };
  }
}
