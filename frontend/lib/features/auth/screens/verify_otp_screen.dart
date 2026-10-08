import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/constants/custom_assets.dart';
import '../../../core/widgets/custom_button.dart';
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
  String _currentOtp = '';

  void _onVerify() {
    if (_formKey.currentState!.validate()) {
      _authCtrl.verifyOtp(widget.email, _currentOtp.trim(), context);
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

              // pin_code_fields v9 — works with package:flutter/material.dart
              PinCodeTextField(
                appContext: context,
                length: 6,
                controller: _otpCtrl,
                keyboardType: TextInputType.number,
                animationType: AnimationType.fade,
                autoFocus: false,
                enableActiveFill: true,
                autoDismissKeyboard: true,
                textStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                ),
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(12.r),
                  fieldHeight: 56.h,
                  fieldWidth: 46.w,
                  activeFillColor: const Color(0xFF282C4A),
                  inactiveFillColor: const Color(0xFF282C4A),
                  selectedFillColor: const Color(0xFF282C4A),
                  activeColor: const Color(0xFFFF4D8D),
                  inactiveColor: Colors.transparent,
                  selectedColor: const Color(0xFFFF4D8D),
                  borderWidth: 1.5,
                ),
                onChanged: (val) => _currentOtp = val,
                onCompleted: (val) => _currentOtp = val,
                validator: (v) => v == null || v.isEmpty
                    ? 'Required'
                    : (v.length < 6 ? 'Enter all 6 digits' : null),
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
