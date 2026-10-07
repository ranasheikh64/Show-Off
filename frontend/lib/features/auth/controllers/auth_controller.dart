import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../../core/storage/hive_service.dart';
import '../models/user_model.dart';
import 'package:dio/dio.dart';
import '../services/auth_service.dart';
import '../../../core/constants/api_url.dart';
import '../../../core/network/dio_client.dart';

class AuthController extends GetxController {
  final AuthService _authService = AuthService();
  
  var isLoading = false.obs;
  var currentUser = Rxn<UserModel>();

  @override
  void onInit() {
    super.onInit();
    _loadUserFromHive();
  }

  void _loadUserFromHive() {
    final userData = HiveService.getUser();
    if (userData != null) {
      currentUser.value = UserModel.fromJson(Map<String, dynamic>.from(userData));
    }
  }

  var loginError = RxnString();

  Future<void> login(String email, String password, BuildContext context) async {
    try {
      isLoading.value = true;
      loginError.value = null; // Reset error on new attempt
      final res = await _authService.login(email, password);
      
      final data = res['data'];
      final token = data['token'];
      final user = UserModel.fromJson(data['user']);
      
      await HiveService.saveToken(token);
      await HiveService.saveUser(data['user']);
      currentUser.value = user;
      
      if (context.mounted) context.go('/home'); // Replace with actual home route later
    } catch (e) {
      String errorMessage = e.toString();
      if (e is DioException && e.response?.data is Map) {
        errorMessage = (e.response!.data as Map)['message'] ?? errorMessage;
        if (e.response?.statusCode == 401) {
          loginError.value = errorMessage;
          return; // Return without showing snackbar
        }
      }
      _showError(context, errorMessage);
    } finally {
      isLoading.value = false;
    }
  }

  var registerEmailError = RxnString();

  Future<void> register(Map<String, dynamic> data, BuildContext context) async {
    try {
      isLoading.value = true;
      registerEmailError.value = null; // Reset error on new attempt
      final res = await _authService.register(data);
      
      // Register only returns success message, no token. Redirect to login.
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Registered successfully!'), backgroundColor: Colors.green));
        context.pop(); // Go back to login screen
      }
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 400) {
        final msg = e.response?.data?['message'];
        if (msg != null && msg.toString().toLowerCase().contains('email already exists')) {
          registerEmailError.value = msg.toString();
          return;
        }
      }
      String errorMessage = e.toString();
      if (e is DioException && e.response?.data is Map) {
        errorMessage = (e.response!.data as Map)['message'] ?? errorMessage;
      }
      _showError(context, errorMessage);
    } finally {
      isLoading.value = false;
    }
  }

  var forgetPasswordError = RxnString();

  Future<void> forgetPassword(String email, BuildContext context) async {
    try {
      isLoading.value = true;
      forgetPasswordError.value = null; // Reset error on new attempt
      await _authService.forgetPassword(email);
      if (context.mounted) {
        context.push('/verify-otp', extra: email);
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (e is DioException && e.response?.data is Map) {
        errorMessage = (e.response!.data as Map)['message'] ?? errorMessage;
      }
      forgetPasswordError.value = errorMessage;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyOtp(String email, String otp, BuildContext context) async {
    try {
      isLoading.value = true;
      await _authService.verifyOtp(email, otp);
      if (context.mounted) {
        context.push('/reset-password', extra: email);
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (e is DioException && e.response?.data is Map) {
        errorMessage = (e.response!.data as Map)['message'] ?? errorMessage;
      }
      _showError(context, errorMessage);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resetPassword(String email, String newPassword, BuildContext context) async {
    try {
      isLoading.value = true;
      await _authService.resetPassword(email, newPassword);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password Reset Successful'), backgroundColor: Colors.green));
        context.go('/login');
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (e is DioException && e.response?.data is Map) {
        errorMessage = (e.response!.data as Map)['message'] ?? errorMessage;
      }
      _showError(context, errorMessage);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data, BuildContext context, {String? imagePath}) async {
    try {
      isLoading.value = true;
      
      // If there's a new image, upload it first
      if (imagePath != null) {
        final formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(imagePath, filename: imagePath.split('/').last),
        });
        final uploadRes = await DioClient.instance.post(ApiUrl.uploadMedia, data: formData);
        data['profileImage'] = uploadRes.data['url'];
      }

      final updatedUser = await _authService.updateProfile(data);
      
      currentUser.value = updatedUser;
      await HiveService.saveUser(updatedUser.toJson());
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (e is DioException && e.response?.data is Map) {
        errorMessage = (e.response!.data as Map)['message'] ?? errorMessage;
      }
      _showError(context, errorMessage);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout(BuildContext context) async {
    await HiveService.clearAuth();
    currentUser.value = null;

    // Reset all GetX controllers so they fetch fresh data on next login.
    // force: true ensures they are removed from memory even if permanent.
    Get.deleteAll(force: true);
    
    // Re-initialize AuthController as it's required globally
    Get.put(AuthController(), permanent: true);

    if (context.mounted) {
      context.go('/login');
    }
  }

  void _showError(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
