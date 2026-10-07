import 'package:dio/dio.dart';
import '../../../core/constants/api_url.dart';
import '../../../core/network/dio_client.dart';
import '../models/chat_model.dart';
import '../../auth/models/user_model.dart';

class ChatApiService {
  final Dio _dio = DioClient.instance;

  Future<Map<String, dynamic>> fetchChats({int page = 1, int limit = 20, String searchQuery = ''}) async {
    final response = await _dio.get(
      ApiUrl.fetchChats,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (searchQuery.isNotEmpty) 'searchQuery': searchQuery,
      },
    );
    final data = response.data;
    if (data is List) {
      // Backward compatibility if backend isn't updated
      return {
        'chats': data.map((json) => ChatModel.fromJson(json)).toList(),
        'hasMore': false,
      };
    }
    return {
      'chats': (data['chats'] as List).map((json) => ChatModel.fromJson(json)).toList(),
      'hasMore': data['hasMore'] ?? false,
    };
  }

  Future<List<UserModel>> searchUsers(String query) async {
    final response = await _dio.get('${ApiUrl.searchUsers}?q=$query');
    final List data = response.data;
    return data.map((json) => UserModel.fromJson(json)).toList();
  }

  Future<List<UserModel>> discoverNearby(Map<String, dynamic> filters) async {
    final response = await _dio.get(ApiUrl.discoverUsers, queryParameters: filters);
    final List data = response.data;
    return data.map((json) => UserModel.fromJson(json)).toList();
  }

  Future<String> uploadMedia(String filePath, {void Function(int, int)? onSendProgress}) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final response = await _dio.post(ApiUrl.uploadMedia, data: formData, onSendProgress: onSendProgress);
    return response.data['url'];
  }
}
