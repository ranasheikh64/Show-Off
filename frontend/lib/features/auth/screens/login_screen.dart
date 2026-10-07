import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AuthController _authCtrl = Get.put(AuthController());

  void _onLogin() {
    if (_formKey.currentState!.validate()) {
      _authCtrl.login(_emailCtrl.text.trim(), _passCtrl.text.trim(), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 40.h),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFFF4D8D), AppTheme.primaryBlue],
                  ).createShader(bounds),
                  child: Text(
                    'Welcome Back',
                    style: TextStyle(fontSize: 32.sp, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
                SizedBox(height: 8.h),
                Text('Log in to continue', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16.sp)),
                SizedBox(height: 40.h),
                CustomTextField(
                  label: 'Email',
                  hint: 'Enter your email',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                SizedBox(height: 16.h),
                Obx(() => CustomTextField(
                  label: 'Password',
                  hint: 'Enter your password',
                  controller: _passCtrl,
                  isPassword: true,
                  errorText: _authCtrl.loginError.value,
                  onChanged: (val) => _authCtrl.loginError.value = null,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                )),
                SizedBox(height: 8.h),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/forget-password'),
                    child: Text('Forgot Password?', style: TextStyle(color: AppTheme.primaryBlue)),
                  ),
                ),
                SizedBox(height: 24.h),
                Obx(() => CustomButton(
                  text: 'Login',
                  gradient: const LinearGradient(colors: [Color(0xFFFF4D8D), AppTheme.primaryBlue]),
                  isLoading: _authCtrl.isLoading.value,
                  onPressed: _onLogin,
                )),
                SizedBox(height: 24.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Don\'t have an account? '),
                    GestureDetector(
                      onTap: () => context.push('/register'),
                      child: Text('Register', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
