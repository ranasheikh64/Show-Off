import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_theme.dart';

class CustomTextField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool isPassword;
  final TextInputType keyboardType;
  final Widget? prefixIcon;
  final String? Function(String?)? validator;
  final String? errorText;
  final void Function(String)? onChanged;
  final bool showStrengthIndicator;

  const CustomTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.validator,
    this.errorText,
    this.onChanged,
    this.showStrengthIndicator = false,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscureText;
  String _password = '';

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  void _onTextChanged(String val) {
    if (widget.isPassword && widget.showStrengthIndicator) {
      setState(() {
        _password = val;
      });
    }
    if (widget.onChanged != null) {
      widget.onChanged!(val);
    }
  }

  double _getPasswordStrength() {
    if (_password.isEmpty) return 0.0;
    double strength = 0.0;
    if (_password.length >= 6) strength += 0.25;
    if (_password.length >= 8) strength += 0.25;
    if (RegExp(r'[A-Z]').hasMatch(_password)) strength += 0.25;
    if (RegExp(r'[0-9!@#\$&*~]').hasMatch(_password)) strength += 0.25;
    return strength;
  }

  Color _getStrengthColor(double strength) {
    if (strength <= 0.25) return Colors.red;
    if (strength <= 0.5) return Colors.orange;
    if (strength <= 0.75) return Colors.yellow.shade700;
    return Colors.green;
  }

  String _getStrengthText(double strength) {
    if (strength == 0) return '';
    if (strength <= 0.25) return 'Weak';
    if (strength <= 0.5) return 'Fair';
    if (strength <= 0.75) return 'Good';
    return 'Strong';
  }

  @override
  Widget build(BuildContext context) {
    final strength = _getPasswordStrength();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: widget.controller,
          obscureText: _obscureText,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          onChanged: _onTextChanged,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 14.sp),
            error: widget.errorText != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: AppTheme.errorRed, size: 14.sp),
                      SizedBox(width: 4.w),
                      Text(widget.errorText!, style: TextStyle(color: AppTheme.errorRed, fontSize: 12.sp)),
                    ],
                  )
                : null,
            prefixIcon: widget.prefixIcon,
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                      color: AppTheme.textSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: AppTheme.errorRed),
            ),
          ),
        ),
        if (widget.isPassword && widget.showStrengthIndicator && _password.isNotEmpty) ...[
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4.r),
                  child: LinearProgressIndicator(
                    value: strength,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(_getStrengthColor(strength)),
                    minHeight: 6.h,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                _getStrengthText(strength),
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: _getStrengthColor(strength),
                ),
              ),
            ],
          ),
        ]
      ],
    );
  }
}
