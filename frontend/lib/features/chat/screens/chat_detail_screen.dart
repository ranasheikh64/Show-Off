import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_theme.dart';
import '../controllers/chat_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import 'package:shimmer/shimmer.dart';
import '../widgets/message_bubble_widget.dart';
import '../widgets/chat_input_widget.dart';
import 'package:intl/intl.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String chatName;

  const ChatDetailScreen({super.key, required this.chatId, required this.chatName});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ChatController _chatCtrl = Get.find<ChatController>();
  final AuthController _authCtrl = Get.find<AuthController>();
  late AutoScrollController _scrollController;
  bool _isPinnedExpanded = false;
  bool _showScrollToBottom = false;

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
        _chatCtrl.loadMessages(widget.chatId, onUnlockFailed: () {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showUnlockDialog();
          });
        });
      });
    }
    _scrollController = AutoScrollController(
      viewportBoundaryGetter: () => Rect.fromLTRB(0, 0, 0, MediaQuery.of(context).padding.bottom),
      axis: Axis.vertical,
    );

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 50) {
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

    ever(_chatCtrl.scrollToMessageIndex, (int index) {
      if (index != -1 && mounted) {
        _scrollController.scrollToIndex(index, preferPosition: AutoScrollPosition.middle);
        _chatCtrl.scrollToMessageIndex.value = -1;
      }
    });
  }

  @override
  void dispose() {
    _chatCtrl.deactivateChat();
    _scrollController.dispose();
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
          child: AlertDialog(
            title: const Text('Unlock Chat'),
            content: TextField(
              controller: pwdCtrl,
              decoration: const InputDecoration(hintText: 'Enter Password'),
              obscureText: true,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back from screen
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _chatCtrl.loadMessages(widget.chatId, password: pwdCtrl.text.trim(), onUnlockFailed: () {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _showUnlockDialog();
                    });
                  });
                },
                child: const Text('Unlock'),
              ),
            ],
          ),
        );
      }
    );
  }

  void _showTimerDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Disappearing Messages'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(title: const Text('Off'), onTap: () { _chatCtrl.setTemporaryTimer(widget.chatId, 0); Navigator.pop(context); }),
              ListTile(title: const Text('30 Seconds'), onTap: () { _chatCtrl.setTemporaryTimer(widget.chatId, 30); Navigator.pop(context); }),
              ListTile(title: const Text('5 Minutes'), onTap: () { _chatCtrl.setTemporaryTimer(widget.chatId, 300); Navigator.pop(context); }),
              ListTile(title: const Text('1 Hour'), onTap: () { _chatCtrl.setTemporaryTimer(widget.chatId, 3600); Navigator.pop(context); }),
            ],
          ),
        );
      },
    );
  }

  void _showLockDialog() {
    final TextEditingController pwdCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Lock Chat'),
          content: TextField(
            controller: pwdCtrl,
            decoration: const InputDecoration(hintText: 'Set Password'),
            obscureText: true,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                _chatCtrl.lockChat(widget.chatId, pwdCtrl.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chat locked')));
              },
              child: const Text('Lock'),
            ),
          ],
        );
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              )
            ]
          ),
          child: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leadingWidth: 40.w,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20.sp),
              onPressed: () => Navigator.pop(context),
            ),
            title: Obx(() {
              final chat = _chatCtrl.chats.firstWhereOrNull((c) => c.id == widget.chatId);
              final otherUser = chat?.users.firstWhereOrNull((u) => u.id != _authCtrl.currentUser.value?.id);
              return Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 20.r,
                        backgroundColor: const Color(0xFF91A3F4), // Light blue-purple like in screenshot
                        child: Text(
                          _getInitials(widget.chatName),
                          style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12.r,
                          height: 12.r,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981), // Green dot
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
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
                          style: TextStyle(color: Colors.black87, fontSize: 16.sp, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Online',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12.sp),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
            actions: [
              Obx(() {
                final chat = _chatCtrl.chats.firstWhereOrNull((c) => c.id == widget.chatId);
                final otherUser = chat?.users.firstWhereOrNull((u) => u.id != _authCtrl.currentUser.value?.id);
                final isBlocked = otherUser != null && (otherUser.isBlocked || _chatCtrl.blockedUserIds.contains(otherUser.id));
                
                return PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.black87),
                  onSelected: (val) {
                    if (val == 'block') {
                      if (otherUser != null) _chatCtrl.blockUser(otherUser.id);
                    } else if (val == 'unblock') {
                      if (otherUser != null) _chatCtrl.unblockUser(otherUser.id);
                    } else if (val == 'timer') {
                      _showTimerDialog();
                    } else if (val == 'timer_off') {
                      _chatCtrl.setTemporaryTimer(widget.chatId, 0);
                    } else if (val == 'lock') {
                      _showLockDialog();
                    } else if (val == 'unlock_chat') {
                      _chatCtrl.disableChatLock(widget.chatId);
                    }
                  },
                  itemBuilder: (context) => [
                    if (isBlocked)
                      const PopupMenuItem(value: 'unblock', child: Text('Unblock User', style: TextStyle(color: Colors.green)))
                    else
                      const PopupMenuItem(value: 'block', child: Text('Block User', style: TextStyle(color: Colors.red))),
                    if (chat != null && chat.disappearingTimer > 0)
                      const PopupMenuItem(value: 'timer_off', child: Text('Turn off Disappearing Messages', style: TextStyle(color: Colors.red)))
                    else
                      const PopupMenuItem(value: 'timer', child: Text('Disappearing Messages')),
                    if (chat?.isLocked == true)
                      const PopupMenuItem(value: 'unlock_chat', child: Text('Disable Chat Lock', style: TextStyle(color: Colors.orange)))
                    else
                      const PopupMenuItem(value: 'lock', child: Text('Lock Chat')),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Obx(() {
            final chat = _chatCtrl.chats.firstWhereOrNull((c) => c.id == widget.chatId);
            if (chat == null || chat.pinnedMessages.isEmpty) {
              return const SizedBox.shrink();
            }

            final isMultiple = chat.pinnedMessages.length > 1;

            if (_isPinnedExpanded && isMultiple) {
              return Container(
                constraints: BoxConstraints(maxHeight: 200.h),
                margin: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FA),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      child: Row(
                        children: [
                          Icon(Icons.push_pin, color: AppTheme.primaryBlue, size: 20.sp),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              "${chat.pinnedMessages.length} Pinned Messages",
                              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14.sp),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.keyboard_arrow_up, size: 24.sp, color: Colors.black87),
                            onPressed: () {
                              setState(() {
                                _isPinnedExpanded = false;
                              });
                            },
                          )
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListWheelScrollView(
                        itemExtent: 75.h,
                        diameterRatio: 1.5,
                        physics: const FixedExtentScrollPhysics(),
                        children: chat.pinnedMessages.map((msgId) {
                          final msg = _chatCtrl.currentMessages.firstWhereOrNull((m) => m.id == msgId);
                          final contentStr = msg != null ? msg.content : 'Message content...';
                          final senderName = msg?.sender?.name ?? 'Unknown';

                          return Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: Material(
                              color: Colors.white,
                              elevation: 2,
                              shadowColor: Colors.black26,
                              borderRadius: BorderRadius.circular(10.r),
                              clipBehavior: Clip.antiAlias,
                              child: ListTile(
                                leading: Container(width: 4.w, color: AppTheme.primaryBlue),
                                title: Text(senderName, style: TextStyle(color: Colors.black87, fontSize: 13.sp, fontWeight: FontWeight.w600)),
                                subtitle: Text(contentStr, style: TextStyle(color: Colors.black54, fontSize: 11.sp), maxLines: 1, overflow: TextOverflow.ellipsis),
                                trailing: IconButton(
                                  icon: Icon(Icons.close, size: 18.sp, color: Colors.grey),
                                  onPressed: () {
                                    _chatCtrl.togglePinMessage(msgId);
                                  },
                                ),
                                onTap: () {
                                  _chatCtrl.highlightMessage(msgId);
                                  setState(() { _isPinnedExpanded = false; });
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
            final lastMsgId = chat.pinnedMessages.isNotEmpty ? chat.pinnedMessages.last : null;
            final lastMsg = _chatCtrl.currentMessages.firstWhereOrNull((m) => m.id == lastMsgId);
            final lastMsgContent = lastMsg != null ? lastMsg.content : 'Pinned message...';

            return GestureDetector(
              onTap: () {
                if (isMultiple) {
                  setState(() {
                    _isPinnedExpanded = true;
                  });
                } else if (lastMsgId != null) {
                  _chatCtrl.highlightMessage(lastMsgId);
                }
              },
              child: Container(
                margin: EdgeInsets.all(12.w),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FA),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  children: [
                    Icon(Icons.push_pin, color: AppTheme.primaryBlue, size: 20.sp),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Pinned Message", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14.sp)),
                          Text(
                            isMultiple ? "${chat.pinnedMessages.length} pinned messages. Tap to expand." : lastMsgContent,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey[600], fontSize: 12.sp),
                          ),
                        ],
                      ),
                    ),
                    if (isMultiple)
                      IconButton(
                        icon: Icon(Icons.keyboard_arrow_down, size: 24.sp, color: Colors.black87),
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
                        icon: Icon(Icons.close, size: 20.sp, color: Colors.black87),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          _chatCtrl.togglePinMessage(chat.pinnedMessages.last);
                        },
                      )
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
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              margin: EdgeInsets.only(bottom: 12.h),
                              height: 50.h,
                              width: 200.w,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }
                  if (_chatCtrl.currentMessages.isEmpty) {
                    return Center(child: Text('Say hi!', style: TextStyle(color: Colors.grey, fontSize: 16.sp)));
                  }
                  
                  final int count = _chatCtrl.currentMessages.length + (_chatCtrl.isFetchingMore.value ? 1 : 0);
                  
                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true, // Show latest at bottom
                    padding: EdgeInsets.all(16.w),
                    itemCount: count,
                    itemBuilder: (context, index) {
                      if (index == _chatCtrl.currentMessages.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      final msg = _chatCtrl.currentMessages[index];
                      final isMe = msg.sender?.id == _authCtrl.currentUser.value?.id;
                      
                      // Date Divider Logic
                      bool showDateDivider = false;
                      if (index == _chatCtrl.currentMessages.length - 1) {
                        showDateDivider = true;
                      } else {
                        final olderMsg = _chatCtrl.currentMessages[index + 1];
                        if (msg.createdAt != null && olderMsg.createdAt != null) {
                          final msgDate = msg.createdAt!.toLocal();
                          final olderDate = olderMsg.createdAt!.toLocal();
                          if (msgDate.year != olderDate.year || msgDate.month != olderDate.month || msgDate.day != olderDate.day) {
                            showDateDivider = true;
                          }
                        } else if (msg.createdAt != null && olderMsg.createdAt == null) {
                          showDateDivider = true;
                        }
                      }

                      String dateText = '';
                      if (showDateDivider && msg.createdAt != null) {
                        final date = msg.createdAt!.toLocal();
                        final now = DateTime.now();
                        final today = DateTime(now.year, now.month, now.day);
                        final yesterday = today.subtract(const Duration(days: 1));
                        final msgDay = DateTime(date.year, date.month, date.day);

                        if (msgDay == today) dateText = 'Today';
                        else if (msgDay == yesterday) dateText = 'Yesterday';
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
                                margin: const EdgeInsets.symmetric(vertical: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E2B30),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  dateText,
                                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                                ),
                              ),
                            MessageBubbleWidget(
                              message: msg,
                              isMe: isMe,
                            ),
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
                          child: Icon(Icons.keyboard_arrow_down, color: AppTheme.primaryBlue, size: 28.sp),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Obx(() {
            final chat = _chatCtrl.chats.firstWhereOrNull((c) => c.id == widget.chatId);
            final otherUser = chat?.users.firstWhereOrNull((u) => u.id != _authCtrl.currentUser.value?.id);
            final isBlocked = otherUser != null && (otherUser.isBlocked || _chatCtrl.blockedUserIds.contains(otherUser.id));
            final isBlockedBy = otherUser?.isBlockedBy ?? false;
            
            if (isBlocked) {
              return Container(
                padding: EdgeInsets.all(16.h),
                color: Colors.grey[200],
                child: Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () {
                      if (otherUser != null) _chatCtrl.unblockUser(otherUser.id);
                    },
                    child: const Text('Unblock User to send messages', style: TextStyle(color: Colors.white)),
                  ),
                ),
              );
            }

            if (isBlockedBy) {
              return Container(
                padding: EdgeInsets.all(16.h),
                color: Colors.grey[200],
                child: const Center(
                  child: Text('You have been blocked by this user', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ),
              );
            }

            return ChatInputWidget(chatId: widget.chatId);
          }),
        ],
      ),
    );
  }
}
