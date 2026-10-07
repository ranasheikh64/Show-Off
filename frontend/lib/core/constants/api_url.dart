class ApiUrl {
  // Adjust base url according to physical device or emulator
  // static const String baseUrl =
  //     'https://jr-connection.onrender.com/api'; // Live Render API
  // static const String socketUrl = 'https://jr-connection.onrender.com';

  static const String baseUrl = 'http://10.0.60.243:5000/api'; // Local IP for physical device
  static const String socketUrl = 'http://10.0.60.243:5000';

  // Auth endpoints
  static const String login = '$baseUrl/auth/login';
  static const String register = '$baseUrl/auth/register';
  static const String forgetPassword = '$baseUrl/auth/forgot-password';
  static const String verifyOtp = '$baseUrl/auth/verify-otp';
  static const String resetPassword = '$baseUrl/auth/reset-password';

  // User endpoints
  static const String updateProfile = '$baseUrl/users/profile';
  static const String discoverUsers = '$baseUrl/users/discover';
  static const String searchUsers = '$baseUrl/users/search';

  // Chat endpoints
  static const String fetchChats = '$baseUrl/chats';
  static const String uploadMedia = '$baseUrl/upload';

  // Show off endpoints
  static const String showOff = '$baseUrl/showoff';
  static const String showOffFeed = '$baseUrl/showoff/feed';
  static const String showOffChoose = '$baseUrl/showoff/choose';
  static String showOffById(String id) => '$baseUrl/showoff/$id';
}
