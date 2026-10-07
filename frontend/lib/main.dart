import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/features/chat/controllers/chat_controller.dart';

import 'core/storage/hive_service.dart';
import 'core/constants/app_theme.dart';
import 'routes/app_router.dart';

import 'package:get/get.dart';

import 'features/auth/controllers/auth_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();

  // Initialize Global Controllers
  Get.put(AuthController(), permanent: true);
  Get.put(ChatController(), permanent: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone X design size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          scaffoldMessengerKey: scaffoldMessengerKey,
          title: 'Show Off',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          routerConfig: appRouter,
        );
      },
    );
  }
}
