import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

class OnboardingController extends GetxController {
  void onGetStarted(BuildContext context) {
    context.go('/login');
  }

  void onWatchDemo() {
    // Handle watch demo action
    print('Watch demo tapped');
  }
}
