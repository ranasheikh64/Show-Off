class UserModel {
  final String id;
  final String name;
  final String username;
  final String email;
  final String? profileImage;
  final String? gender;
  final int? age;

  UserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    this.profileImage,
    this.gender,
    this.age,
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
    };
  }
}
