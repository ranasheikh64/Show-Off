import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/widgets/custom_button.dart';
import '../services/chat_api_service.dart';
import '../services/socket_service.dart';
import '../../auth/models/user_model.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _apiService = ChatApiService();
  List<UserModel> _results = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadNearby();
  }

  void _loadNearby() async {
    setState(() => _isLoading = true);
    try {
      // Mock coordinates. In a real app, use geolocator to get current lat/lng
      final users = await _apiService.discoverNearby({'lat': 23.8103, 'lng': 90.4125, 'maxDistance': 50});
      setState(() => _results = users);
    } catch (e) {
      print(e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _initiateChat(UserModel user) {
    SocketService.emit('access_chat', user.id);
    context.push('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Discover Nearby')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: EdgeInsets.all(16.w),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, crossAxisSpacing: 16.w, mainAxisSpacing: 16.w, childAspectRatio: 0.8,
              ),
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final user = _results[index];
                return Container(
                  decoration: BoxDecoration(
                    color: AppTheme.lightBlue,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(radius: 40.r, child: Text(user.name[0], style: TextStyle(fontSize: 24.sp))),
                      SizedBox(height: 12.h),
                      Text(user.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
                      SizedBox(height: 4.h),
                      Text(user.gender ?? 'Unknown', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13.sp)),
                      SizedBox(height: 12.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: CustomButton(text: 'Chat', onPressed: () => _initiateChat(user), height: 36.h),
                      )
                    ],
                  ),
                );
              },
            ),
    );
  }
}
