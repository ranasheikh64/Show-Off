import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static const String authBox = 'authBox';
  static const String tokenKey = 'jwt_token';
  static const String userKey = 'user_data';

  static const String messagesBox = 'messagesBox';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(authBox);
    await Hive.openBox(messagesBox);
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
    final auth = Hive.box(authBox);
    await auth.clear();
    final msgs = Hive.box(messagesBox);
    await msgs.clear();
  }

  static Map<String, dynamic> _deepCastMap(Map<dynamic, dynamic> map) {
    Map<String, dynamic> result = {};
    map.forEach((key, value) {
      if (value is Map) {
        result[key.toString()] = _deepCastMap(value);
      } else if (value is List) {
        result[key.toString()] = value.map((e) => e is Map ? _deepCastMap(e) : e).toList();
      } else {
        result[key.toString()] = value;
      }
    });
    return result;
  }

  static Future<void> saveMessagesLocal(String chatId, List<Map<String, dynamic>> messages) async {
    final box = Hive.box(messagesBox);
    List<dynamic> existing = box.get(chatId, defaultValue: []) ?? [];
    
    Map<String, Map<String, dynamic>> msgMap = {};
    for (var e in existing) {
      final msg = _deepCastMap(e as Map<dynamic, dynamic>);
      msgMap[msg['_id'] ?? msg['id']] = msg;
    }
    
    for (var msg in messages) {
      msgMap[msg['_id'] ?? msg['id']] = msg;
    }
    
    await box.put(chatId, msgMap.values.toList());
  }
  
  static Future<void> saveSingleMessageLocal(String chatId, Map<String, dynamic> msg) async {
    final box = Hive.box(messagesBox);
    List<dynamic> existing = box.get(chatId, defaultValue: []) ?? [];
    
    List<Map<String, dynamic>> existingList = existing.map((e) => _deepCastMap(e as Map<dynamic, dynamic>)).toList();
    
    bool found = false;
    for (int i = 0; i < existingList.length; i++) {
      if ((existingList[i]['_id'] ?? existingList[i]['id']) == (msg['_id'] ?? msg['id'])) {
        existingList[i] = msg;
        found = true;
        break;
      }
    }
    if (!found) {
      existingList.add(msg); // normally we prepend or sort later
    }
    await box.put(chatId, existingList);
  }
  
  static List<Map<String, dynamic>> getLocalMessages(String chatId) {
    final box = Hive.box(messagesBox);
    List<dynamic> existing = box.get(chatId, defaultValue: []) ?? [];
    return existing.map((e) => _deepCastMap(e as Map<dynamic, dynamic>)).toList();
  }
}
