import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static const String authBox = 'authBox';
  static const String tokenKey = 'jwt_token';
  static const String userKey = 'user_data';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(authBox);
  }

  static Future<void> saveToken(String token) async {
    final box = Hive.box(authBox);
    await box.put(tokenKey, token);
  }

  static String? getToken() {
    final box = Hive.box(authBox);
    return box.get(tokenKey);
  }

  static Future<void> saveUser(Map<String, dynamic> userData) async {
    final box = Hive.box(authBox);
    await box.put(userKey, userData);
  }

  static Map<dynamic, dynamic>? getUser() {
    final box = Hive.box(authBox);
    return box.get(userKey);
  }

  static Future<void> clearAuth() async {
    final box = Hive.box(authBox);
    await box.clear();
  }
}
