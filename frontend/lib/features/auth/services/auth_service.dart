import 'package:dio/dio.dart';
import '../../../core/constants/api_url.dart';
import '../../../core/network/dio_client.dart';
import '../models/user_model.dart';

class AuthService {
  final Dio _dio = DioClient.instance;

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post(ApiUrl.login, data: {
      'email': email,
      'password': password,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final response = await _dio.post(ApiUrl.register, data: data);
    return response.data;
  }

  Future<void> forgetPassword(String email) async {
    await _dio.post(ApiUrl.forgetPassword, data: {'email': email});
  }

  Future<void> verifyOtp(String email, String otp) async {
    await _dio.post(ApiUrl.verifyOtp, data: {'email': email, 'otp': otp});
  }

  Future<void> resetPassword(String email, String newPassword) async {
    await _dio.post(ApiUrl.resetPassword, data: {
      'email': email,
      'newPassword': newPassword,
    });
  }
  
  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    final response = await _dio.put(ApiUrl.updateProfile, data: data);
    return UserModel.fromJson(response.data['user']);
  }
}
