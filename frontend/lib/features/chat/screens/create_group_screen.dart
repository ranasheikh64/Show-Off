import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../services/socket_service.dart';
import '../../auth/models/user_model.dart';
import '../services/chat_api_service.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _apiService = ChatApiService();
  final _nameCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  
  List<UserModel> _searchResults = [];
  List<UserModel> _selectedUsers = [];

  void _search() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) return;
    
    try {
      final users = await _apiService.searchUsers(query);
      setState(() => _searchResults = users);
    } catch (e) {
      print(e);
    }
  }

  void _createGroup() {
    if (_nameCtrl.text.isEmpty || _selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter name and select users')));
      return;
    }
    
    SocketService.emit('create_group', {
      'chatName': _nameCtrl.text.trim(),
      'users': _selectedUsers.map((u) => u.id).toList(),
    });
    
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Create Group')),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            CustomTextField(label: 'Group Name', hint: 'Enter group name', controller: _nameCtrl),
            SizedBox(height: 16.h),
            CustomTextField(
              label: 'Add Participants', hint: 'Search by username', controller: _searchCtrl,
              prefixIcon: IconButton(icon: const Icon(Icons.search), onPressed: _search),
            ),
            if (_selectedUsers.isNotEmpty) ...[
              SizedBox(height: 12.h),
              Wrap(
                spacing: 8.w,
                children: _selectedUsers.map((u) => Chip(
                  label: Text(u.name),
                  onDeleted: () => setState(() => _selectedUsers.remove(u)),
                )).toList(),
              ),
            ],
            SizedBox(height: 16.h),
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final user = _searchResults[index];
                  final isSelected = _selectedUsers.any((u) => u.id == user.id);
                  return CheckboxListTile(
                    title: Text(user.name),
                    subtitle: Text('@${user.username}'),
                    value: isSelected,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) _selectedUsers.add(user);
                        else _selectedUsers.removeWhere((u) => u.id == user.id);
                      });
                    },
                  );
                },
              ),
            ),
            CustomButton(text: 'Create', onPressed: _createGroup),
          ],
        ),
      ),
    );
  }
}
