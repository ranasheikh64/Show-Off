import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/constants/custom_assets.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../controllers/auth_controller.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AuthController _authCtrl = Get.find<AuthController>();

  void _onReset() {
    if (_formKey.currentState!.validate()) {
      if (_passCtrl.text != _confirmCtrl.text) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match'), backgroundColor: Colors.red));
        return;
      }
      _authCtrl.resetPassword(widget.email, _passCtrl.text.trim(), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF16182B),
      appBar: AppBar(),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Image.asset(
                  CustomAssets.transparentLogo,
                  height: 100.h,
                ),
              ),
              SizedBox(height: 20.h),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFFF4D8D), AppTheme.primaryBlue],
                ).createShader(bounds),
                child: Text(
                  'Reset Password',
                  style: TextStyle(fontSize: 32.sp, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
              SizedBox(height: 8.h),
              Text('Enter new password', style: TextStyle(color: Colors.white70, fontSize: 16.sp)),
              SizedBox(height: 32.h),
              CustomTextField(
                label: 'New Password',
                hint: 'Enter new password',
                controller: _passCtrl,
                isPassword: true,
                showStrengthIndicator: true,
                validator: (v) => v!.length < 6 ? 'Min 6 chars' : null,
              ),
              SizedBox(height: 16.h),
              CustomTextField(
                label: 'Confirm Password',
                hint: 'Re-enter new password',
                controller: _confirmCtrl,
                isPassword: true,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 32.h),
              Obx(() => CustomButton(
                text: 'Reset Password',
                gradient: const LinearGradient(colors: [Color(0xFFFF4D8D), AppTheme.primaryBlue]),
                isLoading: _authCtrl.isLoading.value,
                onPressed: _onReset,
              )),
            ],
          ),
        ),
      ),
    );
  }
}
