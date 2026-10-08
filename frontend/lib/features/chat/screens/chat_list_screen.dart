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
  final ChatController _chatCtrl = Get.find<ChatController>();
  final AuthController _authCtrl = Get.find<AuthController>();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _chatCtrl.fetchChats();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
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
      backgroundColor: const Color(0xFF0B0C1F),
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0B0C1F),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60.h),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search chats...',
                hintStyle: TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                contentPadding: EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: Colors.white),
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
                Icon(
                  Icons.chat_bubble_outline,
                  size: 48.sp,
                  color: Colors.grey[300],
                ),
                SizedBox(height: 16.h),
                Text(
                  'No chats found',
                  style: TextStyle(fontSize: 16.sp, color: Colors.white54),
                ),
              ],
            ),
          );
        }
        final pinnedChats = _chatCtrl.chats.where((c) => c.isPinned).toList();
        final unpinnedChats = _chatCtrl.chats
            .where((c) => !c.isPinned)
            .toList();

        return CustomScrollView(
          controller: _scrollController,
          slivers: [
            if (pinnedChats.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.push_pin, size: 16.sp, color: Colors.grey),
                      SizedBox(width: 8.w),
                      Text(
                        'Pinned Chats',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                  return _buildChatTile(
                    chat,
                    key: ValueKey(chat.id),
                    index: index,
                  );
                },
              ),
              SliverToBoxAdapter(
                child: Divider(height: 1, color: Colors.white10),
              ),
            ],
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final chat = unpinnedChats[index];
                return _buildChatTile(chat, key: ValueKey(chat.id));
              }, childCount: unpinnedChats.length),
            ),
          ],
        );
      }),
    );
  }

  void _showChatContextMenu(BuildContext context, ChatModel chat) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E213A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 12.h),
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 16.h),
              ListTile(
                leading: Icon(
                  chat.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                  color: Colors.white,
                ),
                title: Text(
                  chat.isPinned ? 'Unpin chat' : 'Pin chat',
                  style: TextStyle(fontSize: 16.sp, color: Colors.white),
                ),
                onTap: () {
                  _chatCtrl.togglePinChat(chat.id);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(
                  chat.isMuted ? Icons.notifications_active_outlined : Icons.notifications_off_outlined,
                  color: Colors.white,
                ),
                title: Text(
                  chat.isMuted ? 'Unmute notifications' : 'Mute notifications',
                  style: TextStyle(fontSize: 16.sp, color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  if (chat.isMuted) {
                    _chatCtrl.unmuteChat(chat.id);
                  } else {
                    _showMuteOptions(context, chat);
                  }
                },
              ),

              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                title: Text(
                  'Delete chat',
                  style: TextStyle(fontSize: 16.sp, color: Colors.redAccent),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirm(context, chat);
                },
              ),
              SizedBox(height: 16.h),
            ],
          ),
        );
      },
    );
  }

  void _showMuteOptions(BuildContext context, ChatModel chat) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E213A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 12.h),
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 16.h),
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Text(
                  'Mute notifications for...',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.timer_outlined, color: Colors.white),
                title: const Text('8 hours', style: TextStyle(color: Colors.white)),
                onTap: () {
                  _chatCtrl.muteChat(chat.id, 8);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today_outlined, color: Colors.white),
                title: const Text('1 week', style: TextStyle(color: Colors.white)),
                onTap: () {
                  _chatCtrl.muteChat(chat.id, 24 * 7);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications_off, color: Colors.white),
                title: const Text('Always', style: TextStyle(color: Colors.white)),
                onTap: () {
                  _chatCtrl.muteChat(chat.id, null);
                  Navigator.pop(context);
                },
              ),
              SizedBox(height: 16.h),
            ],
          ),
        );
      },
    );
  }


  void _showDeleteConfirm(BuildContext context, ChatModel chat) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1E213A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_outline, color: Colors.redAccent, size: 48.sp),
              SizedBox(height: 16.h),
              Text(
                'Delete Chat',
                style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.h),
              Text(
                'Are you sure you want to delete this chat? This cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14.sp),
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel', style: TextStyle(color: Colors.white70, fontSize: 16.sp)),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _chatCtrl.deleteChat(chat.id);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      child: Text('Delete', style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatTile(ChatModel chat, {Key? key, int? index}) {
    final otherUser = chat.isGroupChat
        ? null
        : chat.users.firstWhereOrNull(
            (u) => u.id != _authCtrl.currentUser.value?.id,
          );

    final name = chat.isGroupChat
        ? (chat.chatName ?? 'Group')
        : (otherUser?.name ?? 'Unknown');
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
            padding: EdgeInsets.only(
              left: 8.w,
              top: 4.h,
              bottom: 4.h,
            ), // padding for easier grab
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
        color: chat.isPinned ? Colors.white.withOpacity(0.05) : Colors.transparent,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          children: [
            // Avatar with online status
            Stack(
              children: [
                CircleAvatar(
                  radius: 26.r,
                  backgroundColor: const Color(0xFF91A3F4), // Light blue-purple
                  backgroundImage: (otherUser?.profileImage != null)
                      ? NetworkImage(otherUser!.profileImage!)
                      : null,
                  child: (otherUser?.profileImage == null)
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20.sp,
                          ),
                        )
                      : null,
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
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (chat.isLocked) ...[
                        SizedBox(width: 6.w),
                        Icon(
                          Icons.lock_outline,
                          size: 14.sp,
                          color: Colors.grey[400],
                        ),
                      ],
                      if (chat.isMuted) ...[
                        SizedBox(width: 6.w),
                        Icon(
                          Icons.notifications_off,
                          size: 14.sp,
                          color: Colors.grey[400],
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      if (tickIcon != null) ...[tickIcon, SizedBox(width: 4.w)],
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
                              color: chat.unreadCount > 0
                                  ? Colors.white
                                  : Colors.white54,
                              fontSize: 14.sp,
                              fontWeight: chat.unreadCount > 0
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            );

                            if (mediaIcon != null) {
                              return Row(
                                children: [
                                  Icon(
                                    mediaIcon,
                                    size: 16.sp,
                                    color: Colors.grey[600],
                                  ),
                                  SizedBox(width: 4.w),
                                  Expanded(
                                    child: Text(
                                      displayText,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: textStyle,
                                    ),
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
                          },
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
                      color: chat.unreadCount > 0
                          ? AppTheme.primaryBlue
                          : Colors.white54,
                      fontSize: 12.sp,
                      fontWeight: chat.unreadCount > 0
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                if (msg?.createdAt != null) SizedBox(height: 6.h),
                if (chat.unreadCount > 0)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      chat.unreadCount.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                      ),
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
