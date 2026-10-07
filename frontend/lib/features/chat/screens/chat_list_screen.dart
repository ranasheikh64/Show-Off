import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_theme.dart';
import '../controllers/chat_controller.dart';
import '../models/chat_model.dart';
import '../../auth/controllers/auth_controller.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatController _chatCtrl = Get.put(ChatController());
  final AuthController _authCtrl = Get.find<AuthController>();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _chatCtrl.fetchChats(loadMore: true);
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _chatCtrl.onSearchQueryChanged(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Messages', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () => _authCtrl.logout(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60.h),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search chats...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Obx(() {
        if (_chatCtrl.isLoading.value && _chatCtrl.chats.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_chatCtrl.chats.isEmpty && !_chatCtrl.isLoading.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 48.sp, color: Colors.grey[300]),
                SizedBox(height: 16.h),
                Text('No chats found', style: TextStyle(fontSize: 16.sp, color: Colors.grey)),
              ],
            )
          );
        }
        final pinnedChats = _chatCtrl.chats.where((c) => c.isPinned).toList();
        final unpinnedChats = _chatCtrl.chats.where((c) => !c.isPinned).toList();

        return CustomScrollView(
          controller: _scrollController,
          slivers: [
            if (pinnedChats.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  child: Row(
                    children: [
                      Icon(Icons.push_pin, size: 16.sp, color: Colors.grey),
                      SizedBox(width: 8.w),
                      Text('Pinned Chats', style: TextStyle(color: Colors.grey, fontSize: 14.sp, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              SliverReorderableList(
                itemCount: pinnedChats.length,
                onReorder: (oldIndex, newIndex) {
                  _chatCtrl.reorderPinnedChats(oldIndex, newIndex);
                },
                itemBuilder: (context, index) {
                  final chat = pinnedChats[index];
                  // Use Key directly on the tile, ReorderableDragStartListener will be inside
                  return _buildChatTile(chat, key: ValueKey(chat.id), index: index);
                },
              ),
              SliverToBoxAdapter(child: Divider(height: 1, color: Colors.grey[200])),
            ],
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final chat = unpinnedChats[index];
                  return _buildChatTile(chat, key: ValueKey(chat.id));
                },
                childCount: unpinnedChats.length,
              ),
            ),
          ],
        );
      }),
    );
  }

  void _showChatContextMenu(BuildContext context, ChatModel chat) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16.r))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(chat.isPinned ? Icons.push_pin_outlined : Icons.push_pin, color: Colors.black87),
                title: Text(chat.isPinned ? 'Unpin chat' : 'Pin chat', style: TextStyle(fontSize: 16.sp)),
                onTap: () {
                  _chatCtrl.togglePinChat(chat.id);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.notifications_off_outlined, color: Colors.black87),
                title: Text('Mute notifications', style: TextStyle(fontSize: 16.sp)),
                onTap: () {
                  Navigator.pop(context);
                  _showMuteOptions(context, chat);
                },
              ),
              ListTile(
                leading: Icon(Icons.clear_all, color: Colors.black87),
                title: Text('Clear history', style: TextStyle(fontSize: 16.sp)),
                onTap: () {
                  Navigator.pop(context);
                  _showClearHistoryConfirm(context, chat);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: Colors.redAccent),
                title: Text('Delete chat', style: TextStyle(fontSize: 16.sp, color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirm(context, chat);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMuteOptions(BuildContext context, ChatModel chat) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16.r))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Text('Mute notifications for...', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                title: const Text('8 hours'),
                onTap: () { _chatCtrl.muteChat(chat.id, 8); Navigator.pop(context); },
              ),
              ListTile(
                title: const Text('1 week'),
                onTap: () { _chatCtrl.muteChat(chat.id, 24 * 7); Navigator.pop(context); },
              ),
              ListTile(
                title: const Text('Always'),
                onTap: () { _chatCtrl.muteChat(chat.id, null); Navigator.pop(context); },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showClearHistoryConfirm(BuildContext context, ChatModel chat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear history'),
        content: const Text('Are you sure you want to clear this chat history?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () { _chatCtrl.clearHistory(chat.id); Navigator.pop(context); },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Clear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, ChatModel chat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete chat'),
        content: const Text('Are you sure you want to delete this chat? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () { _chatCtrl.deleteChat(chat.id); Navigator.pop(context); },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTile(ChatModel chat, {Key? key, int? index}) {
    final otherUser = chat.isGroupChat 
        ? null 
        : chat.users.firstWhereOrNull((u) => u.id != _authCtrl.currentUser.value?.id);
    
    final name = chat.isGroupChat ? (chat.chatName ?? 'Group') : (otherUser?.name ?? 'Unknown');
    final msg = chat.latestMessage;
    final msgText = msg?.content ?? 'No messages yet';
    final isMe = msg?.sender?.id == _authCtrl.currentUser.value?.id;
    final isOnline = otherUser?.isOnline ?? false;

    // Tick logic
    Widget? tickIcon;
    if (msg != null && isMe) {
      if (msg.readBy.isNotEmpty) {
        tickIcon = Icon(Icons.done_all, size: 16.sp, color: Colors.blue);
      } else if (msg.deliveredTo.isNotEmpty) {
        tickIcon = Icon(Icons.done_all, size: 16.sp, color: Colors.grey);
      } else {
        tickIcon = Icon(Icons.done, size: 16.sp, color: Colors.grey);
      }
    }

    Widget? pinWidget;
    if (chat.isPinned) {
      pinWidget = Icon(Icons.push_pin, size: 16.sp, color: Colors.grey);
      if (index != null) {
        // If it's in the reorderable list, make the pin icon the drag handle!
        pinWidget = ReorderableDragStartListener(
          index: index,
          child: Padding(
            padding: EdgeInsets.only(left: 8.w, top: 4.h, bottom: 4.h), // padding for easier grab
            child: pinWidget,
          ),
        );
      } else {
        pinWidget = Padding(
          padding: EdgeInsets.only(left: 8.w),
          child: pinWidget,
        );
      }
    }

    return InkWell(
      key: key,
      onTap: () {
        context.push('/chat/${chat.id}', extra: name);
      },
      onLongPress: () {
        _showChatContextMenu(context, chat);
      },
      child: Container(
        color: chat.isPinned ? Colors.grey[50] : Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          children: [
            // Avatar with online status
            Stack(
              children: [
                CircleAvatar(
                  radius: 26.r,
                  backgroundColor: const Color(0xFF91A3F4), // Light blue-purple
                  child: Text(
                    name[0].toUpperCase(), 
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20.sp)
                  ),
                ),
                if (isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14.r,
                      height: 14.r,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 16.w),
            // Middle section (Name and Message)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp, color: Colors.black87),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      if (tickIcon != null) ...[
                        tickIcon,
                        SizedBox(width: 4.w),
                      ],
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            IconData? mediaIcon;
                            String displayText = msgText;

                            if (msgText.startsWith('[AUDIO]')) {
                              mediaIcon = Icons.mic;
                              displayText = 'Audio';
                            } else if (msgText.startsWith('[IMAGE]')) {
                              mediaIcon = Icons.image;
                              displayText = 'Photo';
                            } else if (msgText.startsWith('[FILE]')) {
                              mediaIcon = Icons.insert_drive_file;
                              displayText = 'File';
                            } else if (msgText.startsWith('[VIDEO]')) {
                              mediaIcon = Icons.videocam;
                              displayText = 'Video';
                            }

                            final textStyle = TextStyle(
                              color: chat.unreadCount > 0 ? Colors.black87 : Colors.grey[600], 
                              fontSize: 14.sp,
                              fontWeight: chat.unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                            );

                            if (mediaIcon != null) {
                              return Row(
                                children: [
                                  Icon(mediaIcon, size: 16.sp, color: Colors.grey[600]),
                                  SizedBox(width: 4.w),
                                  Expanded(
                                    child: Text(displayText, maxLines: 1, overflow: TextOverflow.ellipsis, style: textStyle),
                                  ),
                                ],
                              );
                            }

                            return Text(
                              msgText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textStyle,
                            );
                          }
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            // Right section (Time and Unread Count)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (msg?.createdAt != null)
                  Text(
                    _formatTime(msg!.createdAt!),
                    style: TextStyle(
                      color: chat.unreadCount > 0 ? AppTheme.primaryBlue : Colors.grey[500],
                      fontSize: 12.sp,
                      fontWeight: chat.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                if (msg?.createdAt != null) SizedBox(height: 6.h),
                if (chat.unreadCount > 0)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      chat.unreadCount.toString(),
                      style: TextStyle(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            if (pinWidget != null) pinWidget,
          ],
        ),
      ),
    );
  }
  
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final localTime = time.toLocal();
    final difference = now.difference(localTime);
    
    if (difference.inDays == 0 && now.day == localTime.day) {
      // Same day, show time
      return '${localTime.hour > 12 ? localTime.hour - 12 : (localTime.hour == 0 ? 12 : localTime.hour)}:${localTime.minute.toString().padLeft(2, '0')} ${localTime.hour >= 12 ? 'PM' : 'AM'}';
    } else if (difference.inDays < 7) {
      // Within a week, show day name
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[localTime.weekday - 1];
    } else {
      // Older, show date
      return '${localTime.day}/${localTime.month}/${localTime.year.toString().substring(2)}';
    }
  }
}
