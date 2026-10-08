import 'package:flutter/material.dart';

import 'dart:ui';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/core/storage/hive_service.dart';
import 'package:frontend/features/chat/models/message_model.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_theme.dart';
import '../controllers/chat_controller.dart';
import '../../auth/controllers/auth_controller.dart';

import 'package:shimmer/shimmer.dart';

import '../widgets/message_bubble_widget.dart';
import '../widgets/chat_input_widget.dart';

import 'package:intl/intl.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String chatName;

  const ChatDetailScreen({
    super.key,
    required this.chatId,
    required this.chatName,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ChatController _chatCtrl = Get.find<ChatController>();
  final AuthController _authCtrl = Get.find<AuthController>();
  late AutoScrollController _scrollController;
  bool _isPinnedExpanded = false;
  bool _showScrollToBottom = false;
  bool _isSearching = false;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final chat = _chatCtrl.chats.firstWhereOrNull((c) => c.id == widget.chatId);
    if (chat?.isLocked == true) {
      _chatCtrl.currentMessages.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showUnlockDialog();
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _chatCtrl.loadMessages(
          widget.chatId,
          onUnlockFailed: () {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showUnlockDialog();
            });
          },
        );
      });
    }
    _scrollController = AutoScrollController(
      viewportBoundaryGetter: () =>
          Rect.fromLTRB(0, 0, 0, MediaQuery.of(context).padding.bottom),
      axis: Axis.vertical,
    );

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 50) {
        _chatCtrl.loadMoreMessages(widget.chatId);
      }
      if (_scrollController.position.pixels > 200) {
        if (!_showScrollToBottom) {
          setState(() {
            _showScrollToBottom = true;
          });
        }
      } else {
        if (_showScrollToBottom) {
          setState(() {
            _showScrollToBottom = false;
          });
        }
      }
    });

    ever(_chatCtrl.scrollToMessageIndex, (int index) async {
      if (index != -1 && mounted) {
        await _scrollController.scrollToIndex(
          index,
          preferPosition: AutoScrollPosition.middle,
        );
        if (mounted) {
          _chatCtrl.scrollToMessageIndex.value = -1;
        }
      }
    });

    ever(_chatCtrl.matchPromptChatId, (String? chatId) {
      if (chatId != null && chatId == widget.chatId && mounted) {
        _showMatchPromptSheet();
        _chatCtrl.matchPromptChatId.value = null; // Reset
      }
    });
  }

  @override
  void dispose() {
    _chatCtrl.deactivateChat();
    _scrollController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showUnlockDialog() {
    final TextEditingController pwdCtrl = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Dialog(
            backgroundColor: const Color(0xFF1E213A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_person_outlined,
                    color: AppTheme.primaryBlue,
                    size: 48.sp,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Unlock Chat',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'This chat is private. Enter your password to view and send messages.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 13.sp),
                  ),
                  SizedBox(height: 24.h),
                  TextField(
                    controller: pwdCtrl,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter Password',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.black26,
                      prefixIcon: const Icon(Icons.key, color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryBlue,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context); // Close dialog
                            Navigator.pop(context); // Go back from screen
                          },
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            side: const BorderSide(color: Colors.grey),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (pwdCtrl.text.isNotEmpty) {
                              Navigator.pop(context);
                              _chatCtrl.loadMessages(
                                widget.chatId,
                                password: pwdCtrl.text.trim(),
                                onUnlockFailed: () {
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    _showUnlockDialog();
                                  });
                                },
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Password cannot be empty'),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Text(
                            'Unlock',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showTimerDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF1E213A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer_outlined,
                  color: AppTheme.primaryBlue,
                  size: 48.sp,
                ),
                SizedBox(height: 16.h),
                Text(
                  'Disappearing Messages',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Text(
                    'For more privacy, new messages will disappear from this chat after the selected time.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 13.sp),
                  ),
                ),
                SizedBox(height: 24.h),
                _buildTimerOption('Off', 0),
                _buildTimerOption('30 Seconds', 30),
                _buildTimerOption('5 Minutes', 300),
                _buildTimerOption('1 Hour', 3600),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimerOption(String title, int seconds) {
    return InkWell(
      onTap: () {
        _chatCtrl.setTemporaryTimer(widget.chatId, seconds);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              seconds == 0
                  ? 'Disappearing messages turned off'
                  : 'Timer set to $title',
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (seconds == 0)
              const Icon(Icons.timer_off_outlined, color: Colors.grey, size: 20)
            else
              const Icon(
                Icons.timer_outlined,
                color: AppTheme.primaryBlue,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  void _showClearHistoryConfirm() {
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
              Icon(Icons.clear_all, color: Colors.orangeAccent, size: 48.sp),
              SizedBox(height: 16.h),
              Text(
                'Clear History',
                style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.h),
              Text(
                'Are you sure you want to clear this chat history?',
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
                        _chatCtrl.clearHistory(widget.chatId);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      child: Text('Clear', style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold)),
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

  void _showLockDialog() {
    final TextEditingController pwdCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF1E213A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline,
                  color: AppTheme.primaryBlue,
                  size: 48.sp,
                ),
                SizedBox(height: 16.h),
                Text(
                  'Lock Chat',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Keep your conversation private. You will need to enter this password every time you want to open this chat.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 13.sp),
                ),
                SizedBox(height: 24.h),
                TextField(
                  controller: pwdCtrl,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Enter a strong password',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.black26,
                    prefixIcon: const Icon(Icons.key, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryBlue,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (pwdCtrl.text.isNotEmpty) {
                            _chatCtrl.lockChat(widget.chatId, pwdCtrl.text);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Chat locked successfully'),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Password cannot be empty'),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          'Lock Now',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    List<String> parts = name.trim().split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }

  void _showMatchPromptSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: const Color(0xFF0B0C1F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Are you matching with ${widget.chatName}?',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12.h),
              Text(
                'You\'ve exchanged a few messages. Let us know if you think this is a match!',
                style: TextStyle(fontSize: 14.sp, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),
              _buildDecisionButton('Match!', 'match', Colors.green),
              SizedBox(height: 12.h),
              _buildDecisionButton('Unmatch', 'unmatch', Colors.red),
              SizedBox(height: 12.h),
              _buildDecisionButton(
                'Not Now',
                'not_now',
                Colors.white54,
                isOutlined: true,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDecisionButton(
    String text,
    String decision,
    Color color, {
    bool isOutlined = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50.h,
      child: isOutlined
          ? OutlinedButton(
              onPressed: () {
                _chatCtrl.submitMatchDecision(widget.chatId, decision);
                Navigator.pop(context);
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: color, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25.r),
                ),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : ElevatedButton(
              onPressed: () {
                _chatCtrl.submitMatchDecision(widget.chatId, decision);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25.r),
                ),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF4A122C),
            Color(0xFF061A35),
          ], // Darker versions of the logo colors
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            decoration: const BoxDecoration(color: Colors.transparent),
            child: AppBar(
              scrolledUnderElevation: 0,
              backgroundColor: Colors.transparent,
              elevation: 0,
              leadingWidth: 40.w,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 20.sp,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: Obx(() {
                if (_isSearching) {
                  return TextField(
                    controller: _searchCtrl,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search message...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.grey[400]),
                    ),
                    style: TextStyle(color: Colors.white, fontSize: 16.sp),
                    onChanged: (val) {
                      setState(() {});
                    },
                  );
                }

                final chat = _chatCtrl.chats.firstWhereOrNull(
                  (c) => c.id == widget.chatId,
                );
                final otherUser = chat?.users.firstWhereOrNull(
                  (u) => u.id != _authCtrl.currentUser.value?.id,
                );
                return Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 20.r,
                          backgroundColor: const Color(
                            0xFF91A3F4,
                          ), // Light blue-purple like in screenshot
                          backgroundImage:
                              (otherUser?.profileImage != null &&
                                  otherUser!.profileImage!.isNotEmpty)
                              ? NetworkImage(otherUser.profileImage!)
                              : null,
                          child:
                              (otherUser?.profileImage != null &&
                                  otherUser!.profileImage!.isNotEmpty)
                              ? null
                              : Text(
                                  _getInitials(widget.chatName),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                        if (otherUser != null && otherUser.isOnline)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 12.r,
                              height: 12.r,
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981), // Green dot
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.chatName,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (otherUser != null)
                            Text(
                              otherUser.isOnline
                                  ? 'Active now'
                                  : (otherUser.lastActive != null
                                        ? 'Active ${timeago.format(otherUser.lastActive!)}'
                                        : 'Offline'),
                              style: TextStyle(
                                color: otherUser.isOnline
                                    ? const Color(0xFF10B981)
                                    : Colors.grey[500],
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
              actions: [
                IconButton(
                  icon: Icon(
                    _isSearching ? Icons.close : Icons.search,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _isSearching = !_isSearching;
                      if (!_isSearching) {
                        _searchCtrl.clear();
                      }
                    });
                  },
                ),
                Obx(() {
                  final chat = _chatCtrl.chats.firstWhereOrNull(
                    (c) => c.id == widget.chatId,
                  );
                  final otherUser = chat?.users.firstWhereOrNull(
                    (u) => u.id != _authCtrl.currentUser.value?.id,
                  );
                  final isBlocked =
                      otherUser != null &&
                      (otherUser.isBlocked ||
                          _chatCtrl.blockedUserIds.contains(otherUser.id));

                  return PopupMenuButton<String>(
                    color: const Color(0xFF1E213A), // Dark theme background
                    icon: Icon(Icons.more_vert, color: Colors.white),
                    onSelected: (val) {
                      if (val == 'block') {
                        if (otherUser != null)
                          _chatCtrl.blockUser(otherUser.id);
                      } else if (val == 'unblock') {
                        if (otherUser != null)
                          _chatCtrl.unblockUser(otherUser.id);
                      } else if (val == 'timer') {
                        _showTimerDialog();
                      } else if (val == 'timer_off') {
                        _chatCtrl.setTemporaryTimer(widget.chatId, 0);
                      } else if (val == 'lock') {
                        _showLockDialog();
                      } else if (val == 'unlock_chat') {
                        _chatCtrl.disableChatLock(widget.chatId);
                      } else if (val == 'clear_history') {
                        _showClearHistoryConfirm();
                      }
                    },
                    itemBuilder: (context) => [
                      if (isBlocked)
                        const PopupMenuItem(
                          value: 'unblock',
                          child: Text(
                            'Unblock User',
                            style: TextStyle(color: Colors.green),
                          ),
                        )
                      else
                        const PopupMenuItem(
                          value: 'block',
                          child: Text(
                            'Block User',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      if (chat != null && chat.disappearingTimer > 0)
                        const PopupMenuItem(
                          value: 'timer_off',
                          child: Text(
                            'Turn off Disappearing Messages',
                            style: TextStyle(color: Colors.red),
                          ),
                        )
                      else
                        const PopupMenuItem(
                          value: 'timer',
                          child: Text(
                            'Disappearing Messages',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      if (chat?.isLocked == true)
                        const PopupMenuItem(
                          value: 'unlock_chat',
                          child: Text(
                            'Disable Chat Lock',
                            style: TextStyle(color: Colors.orange),
                          ),
                        )
                      else
                        const PopupMenuItem(
                          value: 'lock',
                          child: Text(
                            'Lock Chat',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'clear_history',
                        child: Text(
                          'Clear History',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
        body: Container(
          color: Colors.transparent,
          child: Column(
            children: [
              Obx(() {
                final chat = _chatCtrl.chats.firstWhereOrNull(
                  (c) => c.id == widget.chatId,
                );
                if (chat == null || chat.pinnedMessages.isEmpty) {
                  return const SizedBox.shrink();
                }

                final isMultiple = chat.pinnedMessages.length > 1;

                if (_isPinnedExpanded && isMultiple) {
                  return Container(
                    constraints: BoxConstraints(maxHeight: 200.h),
                    margin: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 8.h,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.push_pin,
                                color: AppTheme.primaryBlue,
                                size: 20.sp,
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: Text(
                                  "${chat.pinnedMessages.length} Pinned Messages",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.keyboard_arrow_up,
                                  size: 24.sp,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPinnedExpanded = false;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListWheelScrollView(
                            itemExtent: 75.h,
                            diameterRatio: 1.5,
                            physics: const FixedExtentScrollPhysics(),
                            children: chat.pinnedMessages.map((msgId) {
                              var msg = _chatCtrl.currentMessages
                                  .firstWhereOrNull((m) => m.id == msgId);
                              if (msg == null) {
                                final localMaps = HiveService.getLocalMessages(
                                  widget.chatId,
                                );
                                final localMsg = localMaps.firstWhereOrNull(
                                  (m) => m['_id'] == msgId || m['id'] == msgId,
                                );
                                if (localMsg != null) {
                                  msg = MessageModel.fromJson(localMsg);
                                }
                              }
                              final contentStr = msg != null
                                  ? msg.content
                                  : 'Loading...';
                              final senderName = msg?.sender?.name ?? 'Unknown';

                              return Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.w),
                                child: Material(
                                  color: Colors.white.withOpacity(0.15),
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
                                  borderRadius: BorderRadius.circular(10.r),
                                  clipBehavior: Clip.antiAlias,
                                  child: ListTile(
                                    leading: Container(
                                      width: 4.w,
                                      color: AppTheme.primaryBlue,
                                    ),
                                    title: Text(
                                      senderName,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      contentStr,
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11.sp,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: IconButton(
                                      icon: Icon(
                                        Icons.close,
                                        size: 18.sp,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () {
                                        _chatCtrl.togglePinMessage(msgId);
                                      },
                                    ),
                                    onTap: () {
                                      bool found = _chatCtrl.highlightMessage(
                                        msgId,
                                      );
                                      if (!found) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Message is too old and not loaded yet.',
                                                ),
                                              ),
                                            );
                                      }
                                      setState(() {
                                        _isPinnedExpanded = false;
                                      });
                                    },
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Single message or collapsed view
                final lastMsgId = chat.pinnedMessages.isNotEmpty
                    ? chat.pinnedMessages.last
                    : null;
                final lastMsg = _chatCtrl.currentMessages.firstWhereOrNull(
                  (m) => m.id == lastMsgId,
                );
                final lastMsgContent = lastMsg != null
                    ? lastMsg.content
                    : 'Pinned message...';

                return GestureDetector(
                  onTap: () {
                    if (isMultiple) {
                      setState(() {
                        _isPinnedExpanded = true;
                      });
                    } else if (lastMsgId != null) {
                      bool found = _chatCtrl.highlightMessage(lastMsgId);
                      if (!found) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Message is too old and not loaded yet.',
                            ),
                          ),
                        );
                      }
                    }
                  },
                  child: Container(
                    margin: EdgeInsets.all(12.w),
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.push_pin,
                          color: AppTheme.primaryBlue,
                          size: 20.sp,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Pinned Message",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.sp,
                                ),
                              ),
                              Text(
                                isMultiple
                                    ? "${chat.pinnedMessages.length} pinned messages. Tap to expand."
                                    : lastMsgContent,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isMultiple)
                          IconButton(
                            icon: Icon(
                              Icons.keyboard_arrow_down,
                              size: 24.sp,
                              color: Colors.black87,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              setState(() {
                                _isPinnedExpanded = true;
                              });
                            },
                          )
                        else
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              size: 20.sp,
                              color: Colors.white,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              _chatCtrl.togglePinMessage(
                                chat.pinnedMessages.last,
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                );
              }),
              Expanded(
                child: Stack(
                  children: [
                    Obx(() {
                      if (_chatCtrl.isInitialLoading.value) {
                        return ListView.builder(
                          reverse: true,
                          padding: EdgeInsets.all(16.w),
                          itemCount: 10,
                          itemBuilder: (context, index) {
                            bool isMe = index % 2 == 0;
                            return Align(
                              alignment: isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Shimmer.fromColors(
                                baseColor: Colors.white.withOpacity(0.1),
                                highlightColor: Colors.white.withOpacity(0.05),
                                child: Container(
                                  margin: EdgeInsets.only(bottom: 12.h),
                                  height: 50.h,
                                  width: 200.w,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16.r),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }
                      if (_chatCtrl.currentMessages.isEmpty) {
                        return Center(
                          child: Text(
                            'Say hi!',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16.sp,
                            ),
                          ),
                        );
                      }

                      final searchQuery = _searchCtrl.text.trim().toLowerCase();

                      List<MessageModel> messagesToSearch =
                          _chatCtrl.currentMessages;
                      if (_isSearching && searchQuery.isNotEmpty) {
                        final localMaps = HiveService.getLocalMessages(
                          widget.chatId,
                        );
                        messagesToSearch = localMaps
                            .map((m) => MessageModel.fromJson(m))
                            .toList();
                        messagesToSearch.sort(
                          (a, b) => (b.createdAt ?? DateTime.now()).compareTo(
                            a.createdAt ?? DateTime.now(),
                          ),
                        );
                      }

                      final filteredMessages =
                          _isSearching && searchQuery.isNotEmpty
                          ? messagesToSearch
                                .where(
                                  (m) => m.content.toLowerCase().contains(
                                    searchQuery,
                                  ),
                                )
                                .toList()
                          : _chatCtrl.currentMessages;

                      if (filteredMessages.isEmpty) {
                        return Center(
                          child: Text(
                            'No messages found.',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16.sp,
                            ),
                          ),
                        );
                      }

                      final int count =
                          filteredMessages.length +
                          (_chatCtrl.isFetchingMore.value &&
                                  (!_isSearching || searchQuery.isEmpty)
                              ? 1
                              : 0);

                      return ListView.builder(
                        controller: _scrollController,
                        reverse: true, // Show latest at bottom
                        padding: EdgeInsets.all(16.w),
                        itemCount: count,
                        itemBuilder: (context, index) {
                          if (index == filteredMessages.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          final msg = filteredMessages[index];
                          final isMe =
                              msg.sender?.id == _authCtrl.currentUser.value?.id;

                          // Date Divider Logic
                          bool showDateDivider = false;
                          if (index == filteredMessages.length - 1) {
                            showDateDivider = true;
                          } else {
                            final olderMsg = filteredMessages[index + 1];
                            if (msg.createdAt != null &&
                                olderMsg.createdAt != null) {
                              final msgDate = msg.createdAt!.toLocal();
                              final olderDate = olderMsg.createdAt!.toLocal();
                              if (msgDate.year != olderDate.year ||
                                  msgDate.month != olderDate.month ||
                                  msgDate.day != olderDate.day) {
                                showDateDivider = true;
                              }
                            } else if (msg.createdAt != null &&
                                olderMsg.createdAt == null) {
                              showDateDivider = true;
                            }
                          }

                          String dateText = '';
                          if (showDateDivider && msg.createdAt != null) {
                            final date = msg.createdAt!.toLocal();
                            final now = DateTime.now();
                            final today = DateTime(
                              now.year,
                              now.month,
                              now.day,
                            );
                            final yesterday = today.subtract(
                              const Duration(days: 1),
                            );
                            final msgDay = DateTime(
                              date.year,
                              date.month,
                              date.day,
                            );

                            if (msgDay == today)
                              dateText = 'Today';
                            else if (msgDay == yesterday)
                              dateText = 'Yesterday';
                            else if (now.difference(date).inDays < 7) {
                              dateText = DateFormat('EEEE').format(date);
                            } else {
                              dateText = DateFormat('MMM d, yyyy').format(date);
                            }
                          }

                          return AutoScrollTag(
                            key: ValueKey(index),
                            controller: _scrollController,
                            index: index,
                            child: Column(
                              children: [
                                if (showDateDivider)
                                  Container(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E2B30),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      dateText,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                MessageBubbleWidget(message: msg, isMe: isMe),
                              ],
                            ),
                          );
                        },
                      );
                    }),
                    if (_showScrollToBottom)
                      Positioned(
                        bottom: 8.h,
                        right: 16.w,
                        child: GestureDetector(
                          onTap: () {
                            _scrollController.animateTo(
                              0,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 20.r,
                              backgroundColor: Colors.transparent,
                              child: Icon(
                                Icons.keyboard_arrow_down,
                                color: AppTheme.primaryBlue,
                                size: 28.sp,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Obx(() {
                final chat = _chatCtrl.chats.firstWhereOrNull(
                  (c) => c.id == widget.chatId,
                );
                final otherUser = chat?.users.firstWhereOrNull(
                  (u) => u.id != _authCtrl.currentUser.value?.id,
                );
                final isBlocked =
                    otherUser != null &&
                    (otherUser.isBlocked ||
                        _chatCtrl.blockedUserIds.contains(otherUser.id));
                final isBlockedBy = otherUser?.isBlockedBy ?? false;

                if (isBlocked) {
                  return SafeArea(
                    bottom: true,
                    top: false,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 16.h,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E213A),
                        border: Border(
                          top: BorderSide(color: Colors.white10, width: 1),
                        ),
                      ),
                      child: Center(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: 24.w,
                              vertical: 12.h,
                            ),
                            side: const BorderSide(color: Colors.greenAccent),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                          ),
                          icon: const Icon(
                            Icons.lock_open,
                            color: Colors.greenAccent,
                          ),
                          label: Text(
                            'Unblock User',
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () {
                            if (otherUser != null) {
                              _chatCtrl.unblockUser(otherUser.id);
                            }
                          },
                        ),
                      ),
                    ),
                  );
                }

                if (isBlockedBy) {
                  return SafeArea(
                    bottom: true,
                    top: false,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 24.h),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E213A),
                        border: Border(
                          top: BorderSide(color: Colors.white10, width: 1),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.block,
                            color: Colors.redAccent,
                            size: 20.sp,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'You have been blocked',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SafeArea(
                  bottom: true,
                  top: false,
                  child: ChatInputWidget(chatId: widget.chatId),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
