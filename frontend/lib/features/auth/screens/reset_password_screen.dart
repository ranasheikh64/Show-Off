import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_theme.dart';
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
      backgroundColor: Colors.white,
      appBar: AppBar(),
      body: Padding(
        padding: EdgeInsets.all(24.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reset Password', style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 8.h),
              Text('Enter new password', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16.sp)),
              SizedBox(height: 32.h),
              CustomTextField(
                label: 'New Password',
                hint: 'Enter new password',
                controller: _passCtrl,
                isPassword: true,
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
