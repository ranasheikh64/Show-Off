import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/constants/custom_assets.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../controllers/auth_controller.dart';

class ForgetPasswordScreen extends StatefulWidget {
  const ForgetPasswordScreen({super.key});

  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AuthController _authCtrl = Get.find<AuthController>();

  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      _authCtrl.forgetPassword(_emailCtrl.text.trim(), context);
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
                  'Forget Password',
                  style: TextStyle(fontSize: 32.sp, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
              SizedBox(height: 8.h),
              Text('Enter email to receive OTP', style: TextStyle(color: Colors.white70, fontSize: 16.sp)),
              SizedBox(height: 32.h),
              Obx(() => CustomTextField(
                label: 'Email',
                hint: 'Enter your email',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                errorText: _authCtrl.forgetPasswordError.value,
                onChanged: (val) => _authCtrl.forgetPasswordError.value = null,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              )),
              SizedBox(height: 32.h),
              Obx(() => CustomButton(
                text: 'Send OTP',
                gradient: const LinearGradient(colors: [Color(0xFFFF4D8D), AppTheme.primaryBlue]),
                isLoading: _authCtrl.isLoading.value,
                onPressed: _onSubmit,
              )),
            ],
          ),
        ),
      ),
    );
  }
}
