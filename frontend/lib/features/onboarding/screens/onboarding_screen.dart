import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/constants/custom_assets.dart';
import '../../../core/widgets/custom_button.dart';
import '../controllers/onboarding_controller.dart';
import '../bindings/onboarding_binding.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure binding is initialized since we are using GoRouter
    OnboardingBinding().dependencies();
    final controller = Get.find<OnboardingController>();

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.asset(
            CustomAssets.onboardingBg,
            fit: BoxFit.cover,
          ),
          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  const Color(0xFF090A1A).withOpacity(0.7),
                  const Color(0xFF090A1A),
                ],
                stops: const [0.4, 0.8, 1.0],
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
              child: Column(
                children: [
                  SizedBox(height: 60.h),
                  // Logo
                  Image.asset(
                    CustomAssets.transparentLogo,
                    height: 220.h,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: 12.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 15.sp,
                          height: 1.5,
                          color: Colors.white.withOpacity(0.75),
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.3,
                        ),
                        children: [
                          const TextSpan(text: 'The ultimate platform to '),
                          TextSpan(
                            text: 'express yourself',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const TextSpan(text: ', connect with others, and chat '),
                          TextSpan(
                            text: 'securely',
                            style: TextStyle(
                              color: const Color(0xFF5CE1E6),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const TextSpan(text: ' with full '),
                          TextSpan(
                            text: 'privacy.',
                            style: TextStyle(
                              color: const Color(0xFFFF3366),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Get Started Button
                  CustomButton(
                    text: 'Get Started',
                    onPressed: () => controller.onGetStarted(context),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFF3366),
                        Color(0xFF8C52FF),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: 50.r,
                  ),
                  SizedBox(height: 16.h),
                  // Watch Demo Button
                  SizedBox(
                    width: double.infinity,
                    height: 50.h,
                    child: OutlinedButton.icon(
                      onPressed: controller.onWatchDemo,
                      icon: const Icon(Icons.play_circle_fill, color: Colors.white),
                      label: Text(
                        'Watch Demo',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF8C52FF), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50.r),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
