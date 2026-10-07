import 'package:go_router/go_router.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/forget_password_screen.dart';
import '../features/auth/screens/verify_otp_screen.dart';
import '../features/auth/screens/reset_password_screen.dart';
import '../features/onboarding/screens/onboarding_screen.dart';

import '../features/chat/screens/chat_list_screen.dart';
import '../features/chat/screens/chat_detail_screen.dart';
import '../features/chat/screens/search_screen.dart';
import '../features/chat/screens/discover_screen.dart';
import '../features/chat/screens/create_group_screen.dart';

import 'package:jwt_decoder/jwt_decoder.dart';
import '../core/storage/hive_service.dart';
import '../features/showoff/screens/showoff_feed_screen.dart';
import '../features/profile/screens/profile_screen.dart';

String getInitialRoute() {
  final token = HiveService.getToken();
  if (token != null && token.isNotEmpty) {
    if (!JwtDecoder.isExpired(token)) {
      return '/home';
    }
  }
  return '/onboarding';
}

final GoRouter appRouter = GoRouter(
  initialLocation: getInitialRoute(),
  routes: [
    GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
    GoRoute(path: '/forget-password', builder: (context, state) => const ForgetPasswordScreen()),
    GoRoute(
      path: '/verify-otp',
      builder: (context, state) => VerifyOtpScreen(email: state.extra as String? ?? ''),
    ),
    GoRoute(
      path: '/reset-password',
      builder: (context, state) => ResetPasswordScreen(email: state.extra as String? ?? ''),
    ),
    GoRoute(path: '/home', builder: (context, state) => const ShowOffFeedScreen()),
    GoRoute(path: '/chat-list', builder: (context, state) => const ChatListScreen()),
    GoRoute(
      path: '/chat/:id',
      builder: (context, state) => ChatDetailScreen(
        chatId: state.pathParameters['id']!,
        chatName: state.extra as String? ?? 'Chat',
      ),
    ),
    GoRoute(path: '/search', builder: (context, state) => const SearchScreen()),
    GoRoute(path: '/discover', builder: (context, state) => const DiscoverScreen()),
    GoRoute(path: '/create-group', builder: (context, state) => const CreateGroupScreen()),
    GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
  ],
);

