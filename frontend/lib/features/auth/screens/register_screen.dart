import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_theme.dart';
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
      backgroundColor: Colors.white,
      appBar: AppBar(leading: IconButton(icon: Icon(Icons.arrow_back), onPressed: () => context.pop())),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create Account', style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 8.h),
              Text('Sign up to get started', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16.sp)),
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
              CustomTextField(
                label: 'Email',
                hint: 'Enter your email',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 16.h),
              CustomTextField(
                label: 'Password',
                hint: 'Enter password',
                controller: _passCtrl,
                isPassword: true,
                validator: (v) => v!.length < 6 ? 'Min 6 chars' : null,
              ),
              SizedBox(height: 32.h),
              Obx(() => CustomButton(
                text: 'Register',
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
