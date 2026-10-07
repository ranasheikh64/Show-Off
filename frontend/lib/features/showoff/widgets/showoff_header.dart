import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_theme.dart';

class ShowOffHeader extends StatefulWidget {
  final bool showMyPosts;
  final ValueChanged<bool> onChanged;
  final ValueChanged<String>? onSearch;

  const ShowOffHeader({
    super.key,
    required this.showMyPosts,
    required this.onChanged,
    this.onSearch,
  });

  @override
  State<ShowOffHeader> createState() => _ShowOffHeaderState();
}

class _ShowOffHeaderState extends State<ShowOffHeader> {
  bool _isSearchExpanded = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (!_isSearchExpanded)
                Expanded(
                  child: ShaderMask(
                    shaderCallback: (r) => const LinearGradient(
                      colors: [Color(0xFFFF4D8D), AppTheme.primaryBlue],
                    ).createShader(r),
                    child: Text(
                      'Show Off',
                      style: TextStyle(
                        fontSize: 30.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              if (_isSearchExpanded)
                Expanded(
                  child: Container(
                    height: 40.h,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      onChanged: widget.onSearch,
                      decoration: InputDecoration(
                        hintText: 'Search posts...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                      ),
                    ),
                  ),
                ),
              IconButton(
                icon: Icon(
                  _isSearchExpanded ? Icons.close_rounded : Icons.search_rounded,
                  color: AppTheme.textPrimary,
                ),
                onPressed: () {
                  setState(() {
                    if (_isSearchExpanded) {
                      _isSearchExpanded = false;
                      _searchController.clear();
                      if (widget.onSearch != null) widget.onSearch!('');
                    } else {
                      _isSearchExpanded = true;
                    }
                  });
                },
              ),
              if (!_isSearchExpanded)
                IconButton(
                  icon: const Icon(Icons.person_rounded, color: AppTheme.textPrimary),
                  onPressed: () => context.push('/profile'),
                ),
            ],
          ),
          if (!_isSearchExpanded) ...[
            Text(
              'Show your best self & find your match',
              style: TextStyle(fontSize: 13.sp, color: AppTheme.textSecondary),
            ),
          ],
          SizedBox(height: 14.h),
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              children: [
                _tab(
                  'Explore',
                  Icons.explore_rounded,
                  !widget.showMyPosts,
                  () => widget.onChanged(false),
                ),
                _tab(
                  'My Posts',
                  Icons.photo_library_rounded,
                  widget.showMyPosts,
                  () => widget.onChanged(true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tab(String label, IconData icon, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    colors: [AppTheme.primaryBlue, Color(0xFF5AA9FF)],
                  )
                : null,
            borderRadius: BorderRadius.circular(26.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18.sp,
                color: selected ? Colors.white : AppTheme.textSecondary,
              ),
              SizedBox(width: 6.w),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14.sp,
                  color: selected ? Colors.white : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

