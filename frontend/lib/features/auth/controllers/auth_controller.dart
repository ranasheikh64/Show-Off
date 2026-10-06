import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../../core/storage/hive_service.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

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

  Future<void> login(String email, String password, BuildContext context) async {
    try {
      isLoading.value = true;
      final res = await _authService.login(email, password);
      
      final data = res['data'];
      final token = data['token'];
      final user = UserModel.fromJson(data['user']);
      
      await HiveService.saveToken(token);
      await HiveService.saveUser(data['user']);
      currentUser.value = user;
      
      if (context.mounted) context.go('/home'); // Replace with actual home route later
    } catch (e) {
      _showError(context, e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> register(Map<String, dynamic> data, BuildContext context) async {
    try {
      isLoading.value = true;
      final res = await _authService.register(data);
      
      // Register only returns success message, no token. Redirect to login.
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Registered successfully!'), backgroundColor: Colors.green));
        context.pop(); // Go back to login screen
      }
    } catch (e) {
      _showError(context, e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> forgetPassword(String email, BuildContext context) async {
    try {
      isLoading.value = true;
      await _authService.forgetPassword(email);
      if (context.mounted) {
        context.push('/verify-otp', extra: email);
      }
    } catch (e) {
      _showError(context, e.toString());
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
      _showError(context, e.toString());
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
      _showError(context, e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout(BuildContext context) async {
    await HiveService.clearAuth();
    currentUser.value = null;
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
