import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/constants/custom_assets.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../controllers/auth_controller.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String email;
  const VerifyOtpScreen({super.key, required this.email});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _otpCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AuthController _authCtrl = Get.find<AuthController>();

  void _onVerify() {
    if (_formKey.currentState!.validate()) {
      _authCtrl.verifyOtp(widget.email, _otpCtrl.text.trim(), context);
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
                  'Verify OTP',
                  style: TextStyle(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Enter OTP sent to ${widget.email}',
                style: TextStyle(color: Colors.white70, fontSize: 16.sp),
              ),
              SizedBox(height: 32.h),
              CustomTextField(
                label: 'OTP Code',
                hint: 'Enter 6-digit OTP',
                controller: _otpCtrl,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (v.length < 6) return 'Enter all 6 digits';
                  return null;
                },
              ),
              SizedBox(height: 32.h),
              Obx(() => CustomButton(
                text: 'Verify',
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF4D8D), AppTheme.primaryBlue],
                ),
                isLoading: _authCtrl.isLoading.value,
                onPressed: _onVerify,
              )),
            ],
          ),
        ),
      ),
    );
  }
}
