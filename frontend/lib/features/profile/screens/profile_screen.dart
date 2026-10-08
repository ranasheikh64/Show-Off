import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../auth/controllers/auth_controller.dart';
import '../../auth/models/user_model.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authCtrl = Get.find<AuthController>();

    return Obx(() {
      final user = authCtrl.currentUser.value;
      if (user == null) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return _ProfileView(user: user, authCtrl: authCtrl);
    });
  }
}

class _ProfileView extends StatelessWidget {
  final UserModel user;
  final AuthController authCtrl;

  const _ProfileView({required this.user, required this.authCtrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0C1F),
      body: RefreshIndicator(
        onRefresh: () async {
          await authCtrl.refreshProfile();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            _buildSliverAppBar(context, user),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildProfileInfo(context, user),
                  SizedBox(height: 24.h),
                  _buildStatsRow(context, user),
                  SizedBox(height: 32.h),
                  _buildMenuSection(context, authCtrl),
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, UserModel user) {
    return SliverAppBar(
      expandedHeight: 280.h,
      pinned: true,
      backgroundColor: const Color(0xFF0B0C1F),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.edit_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
          },
        ),
        SizedBox(width: 8.w),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1A1040),
                    Color(0xFF0D1B4B),
                    Color(0xFF0B0C1F),
                  ],
                ),
              ),
            ),
            // Glowing orbs
            Positioned(
              top: -40,
              left: -40,
              child: Container(
                width: 200.w,
                height: 200.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFF4D8D).withOpacity(0.15),
                ),
              ),
            ),
            Positioned(
              top: 20,
              right: -60,
              child: Container(
                width: 180.w,
                height: 180.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF007BFF).withOpacity(0.12),
                ),
              ),
            ),
            // Avatar
            Positioned(
              bottom: 60.h,
              left: 0,
              right: 0,
              child: Center(
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF4D8D), Color(0xFF007BFF)],
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 52.r,
                        backgroundColor: const Color(0xFF1A1040),
                        child: user.profileImage != null
                            ? ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: user.profileImage!,
                                  width: 100.w,
                                  height: 100.w,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) =>
                                      _avatarFallback(user.name),
                                ),
                              )
                            : _avatarFallback(user.name),
                      ),
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 18.w,
                        height: 18.w,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C853),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF0B0C1F),
                            width: 2.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarFallback(String name) {
    return Text(
      name.isNotEmpty ? name[0].toUpperCase() : '?',
      style: TextStyle(
        fontSize: 36.sp,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildProfileInfo(BuildContext context, UserModel user) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 0),
      child: Column(
        children: [
          // Name
          ShaderMask(
            shaderCallback: (r) => const LinearGradient(
              colors: [Color(0xFFFF4D8D), Color(0xFF007BFF)],
            ).createShader(r),
            child: Text(
              user.name,
              style: TextStyle(
                fontSize: 26.sp,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(height: 4.h),
          // Username
          Text(
            '@${user.username}',
            style: TextStyle(
              fontSize: 15.sp,
              color: Colors.white54,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 16.h),
          // Info chips
          Wrap(
            spacing: 10.w,
            runSpacing: 8.h,
            alignment: WrapAlignment.center,
            children: [
              if (user.gender != null && user.gender!.isNotEmpty)
                _chip(
                  icon: user.gender!.toLowerCase() == 'male'
                      ? Icons.male_rounded
                      : Icons.female_rounded,
                  label: user.gender!,
                ),
              if (user.age != null)
                _chip(icon: Icons.cake_rounded, label: '${user.age} years old'),
              _chip(icon: Icons.email_rounded, label: user.email),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip({required IconData icon, required String label}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: const Color(0xFFFF4D8D)),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, UserModel user) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.07),
              Colors.white.withOpacity(0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            _statItem('Posts', user.postsCount.toString()),
            _statDivider(),
            _statItem('Loved', user.lovedByCount.toString()),
            _statDivider(),
            _statItem('Matched', user.matchedCount.toString()),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          ShaderMask(
            shaderCallback: (r) => const LinearGradient(
              colors: [Color(0xFFFF4D8D), Color(0xFF007BFF)],
            ).createShader(r),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(fontSize: 12.sp, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _statDivider() {
    return Container(width: 1, height: 40.h, color: Colors.white12);
  }

  Widget _buildMenuSection(BuildContext context, AuthController authCtrl) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 12.h),
          _menuCard(
            children: [
              _menuTile(
                icon: Icons.person_outline_rounded,
                label: 'Edit Profile',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                },
              ),
              _menuDivider(),
              _menuTile(
                icon: Icons.lock_outline_rounded,
                label: 'Privacy & Security',
                onTap: () {},
              ),
              _menuDivider(),
              _menuTile(
                icon: Icons.notifications_none_rounded,
                label: 'Notifications',
                onTap: () {},
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Text(
            'More',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 12.h),
          _menuCard(
            children: [
              _menuTile(
                icon: Icons.help_outline_rounded,
                label: 'Help & Support',
                onTap: () {},
              ),
              _menuDivider(),
              _menuTile(
                icon: Icons.info_outline_rounded,
                label: 'About Show Off',
                onTap: () {},
              ),
            ],
          ),
          SizedBox(height: 20.h),
          // Logout button
          GestureDetector(
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: const Color(0xFF1A1040),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  title: const Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: const Text(
                    'Are you sure you want to logout?',
                    style: TextStyle(color: Colors.white60),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Logout',
                        style: TextStyle(
                          color: Color(0xFFFF4D8D),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                authCtrl.logout(context);
              }
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7B0000), Color(0xFFBF0000)],
                ),
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.logout_rounded, color: Colors.white),
                  SizedBox(width: 10.w),
                  Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(children: children),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF4D8D).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(icon, size: 18.sp, color: const Color(0xFFFF4D8D)),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white24,
              size: 20.sp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuDivider() {
    return Divider(
      height: 1,
      color: Colors.white.withOpacity(0.06),
      indent: 56.w,
    );
  }
}
