import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_theme.dart';
import '../services/chat_api_service.dart';
import '../services/socket_service.dart';
import '../../auth/models/user_model.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _apiService = ChatApiService();
  final _searchCtrl = TextEditingController();
  List<UserModel> _results = [];
  bool _isLoading = false;

  void _search() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      final users = await _apiService.searchUsers(query);
      setState(() => _results = users);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _initiateChat(UserModel user) {
    SocketService.emit('access_chat', user.id);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: TextField(
          controller: _searchCtrl,
          onSubmitted: (_) => _search(),
          decoration: const InputDecoration(hintText: 'Search by username...', border: InputBorder.none),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: _search),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final user = _results[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.lightBlue,
                    child: Text(user.name[0], style: const TextStyle(color: AppTheme.primaryBlue)),
                  ),
                  title: Text(user.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16.sp)),
                  subtitle: Text('@${user.username}', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14.sp)),
                  onTap: () => _initiateChat(user),
                );
              },
            ),
    );
  }
}
