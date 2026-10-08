import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/constants/custom_assets.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../controllers/auth_controller.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AuthController _authCtrl = Get.find<AuthController>();

  void _onRegister() {
    if (_formKey.currentState!.validate()) {
      _authCtrl.register({
        'name': _nameCtrl.text.trim(),
        'username': _userCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'password': _passCtrl.text.trim(),
      }, context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF16182B),
      appBar: AppBar(leading: IconButton(icon: Icon(Icons.arrow_back), onPressed: () => context.pop())),
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
                  'Create Account',
                  style: TextStyle(fontSize: 32.sp, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
              SizedBox(height: 8.h),
              Text('Sign up to get started', style: TextStyle(color: Colors.white70, fontSize: 16.sp)),
              SizedBox(height: 32.h),
              CustomTextField(
                label: 'Full Name',
                hint: 'Enter your name',
                controller: _nameCtrl,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 16.h),
              CustomTextField(
                label: 'Username',
                hint: 'Enter unique username',
                controller: _userCtrl,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 16.h),
              Obx(() => CustomTextField(
                label: 'Email',
                hint: 'Enter your email',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                errorText: _authCtrl.registerEmailError.value,
                onChanged: (val) => _authCtrl.registerEmailError.value = null,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              )),
              SizedBox(height: 16.h),
              CustomTextField(
                label: 'Password',
                hint: 'Enter password',
                controller: _passCtrl,
                isPassword: true,
                showStrengthIndicator: true,
                validator: (v) => v!.length < 6 ? 'Min 6 chars' : null,
              ),
              SizedBox(height: 32.h),
              Obx(() => CustomButton(
                text: 'Register',
                gradient: const LinearGradient(colors: [Color(0xFFFF4D8D), AppTheme.primaryBlue]),
                isLoading: _authCtrl.isLoading.value,
                onPressed: _onRegister,
              )),
            ],
          ),
        ),
      ),
    );
  }
}
