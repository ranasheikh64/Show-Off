// ignore_for_file: unused_local_variable

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:popover/popover.dart';
import 'package:animated_emoji/animated_emoji.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../../core/constants/app_theme.dart';
import '../controllers/chat_controller.dart';

import 'dart:io';

import '../models/message_model.dart';

import 'package:intl/intl.dart';

import 'countdown_widget.dart';
import 'full_screen_image_viewer.dart';

class MessageBubbleWidget extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const MessageBubbleWidget({
    super.key,
    required this.message,
    required this.isMe,
  });

  void _showOptions(BuildContext context) {
    final messageId = message.id;
    if (messageId.isEmpty || message.isUploading) return;

    showPopover(
      context: context,
      bodyBuilder: (context) => _buildContextMenu(context),
      direction: PopoverDirection.top,
      width: 250.w,
      height: 350.h,
      arrowHeight: 15,
      arrowWidth: 30,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black26,
    );
  }

  Widget _buildContextMenu(BuildContext context) {
    final chatCtrl = Get.find<ChatController>();
    return Material(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Emoji Reaction Row
          Container(
            height: 50.h,
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(25.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildEmojiReaction(context, AnimatedEmojis.heart),
                _buildEmojiReaction(context, AnimatedEmojis.thumbsUp),
                _buildEmojiReaction(context, AnimatedEmojis.laughing),
                _buildEmojiReaction(context, AnimatedEmojis.sad),
                IconButton(
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showAllEmojis(context);
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),

          // Options List
          // Options List
          Material(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(16.r),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildMenuOption(Icons.reply, "Reply", () {
                  chatCtrl.setReplyTo(message);
                  Navigator.of(context).pop();
                }),
                Builder(
                  builder: (ctx) {
                    final chat = chatCtrl.chats.firstWhereOrNull((c) => c.id == chatCtrl.activeChatId.value);
                    final isPinned = chat?.pinnedMessages.contains(message.id) ?? false;
                    
                    return _buildMenuOption(
                      isPinned ? Icons.push_pin_outlined : Icons.push_pin, 
                      isPinned ? "Unpin" : "Pin", 
                      () {
                        Navigator.of(context).pop();
                        
                        if (isPinned) {
                          // Unpin generic (from both local and global)
                          chatCtrl.togglePinMessage(message.id);
                          return;
                        }
                        
                        showDialog(
                          context: context,
                          builder: (context) {
                            return Dialog(
                              backgroundColor: const Color(0xFF1E213A),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.push_pin,
                                      color: Colors.blue,
                                      size: 48,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Pin Message',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Where would you like to pin this message?',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    InkWell(
                                      onTap: () {
                                        chatCtrl.togglePinMessage(message.id, isGlobal: false);
                                        Navigator.pop(context);
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.white10),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Center(
                                          child: Text(
                                            'Pin for me',
                                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    InkWell(
                                      onTap: () {
                                        chatCtrl.togglePinMessage(message.id, isGlobal: true);
                                        Navigator.pop(context);
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.blue,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Center(
                                          child: Text(
                                            'Pin for everyone',
                                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }
                    );
                  }
                ),
                _buildMenuOption(Icons.copy, "Copy Text", () {
                  Clipboard.setData(ClipboardData(text: message.content));
                  Navigator.of(context).pop();
                }),
                if (isMe)
                  _buildMenuOption(Icons.delete, "Delete", () {
                    chatCtrl.deleteMessage(message.id, true);
                    Navigator.of(context).pop();
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiReaction(BuildContext context, AnimatedEmojiData emoji) {
    return GestureDetector(
      onTap: () {
        Get.find<ChatController>().reactToMessage(message.id, emoji.id);
        Navigator.of(context).pop();
      },
      child: AnimatedEmoji(emoji, size: 35.w),
    );
  }

  void _showAllEmojis(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return SizedBox(
          height: 400.h,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                child: Text(
                  "Reactions",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: EmojiPicker(
                  onEmojiSelected: (category, emoji) {
                    Get.find<ChatController>().reactToMessage(
                      message.id,
                      emoji.emoji,
                    );
                    Navigator.of(context).pop();
                  },
                  config: Config(
                    emojiViewConfig: EmojiViewConfig(
                      backgroundColor: Colors.grey.shade900,
                      columns: 8,
                      emojiSizeMax: 28,
                    ),
                    categoryViewConfig: CategoryViewConfig(
                      backgroundColor: Colors.grey.shade900,
                      dividerColor: Colors.transparent,
                      indicatorColor: AppTheme.primaryBlue,
                      iconColorSelected: AppTheme.primaryBlue,
                      iconColor: Colors.grey,
                    ),
                    bottomActionBarConfig: const BottomActionBarConfig(
                      showBackspaceButton: false,
                      showSearchViewButton: false,
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuOption(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white, size: 22.sp),
      title: Text(
        title,
        style: TextStyle(color: Colors.white, fontSize: 14.sp),
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = message.content;
    final isMedia = content.startsWith('[IMAGE]') || (content.startsWith('http') &&
        (content.endsWith('.jpg') ||
            content.endsWith('.png') ||
            content.endsWith('.jpeg') ||
            content.endsWith('.gif')));

// Simplification: length > 1 means someone else read it

    if (message.isSystemMessage) {
      String displayMsg = message.content;
      bool isTimerOff = message.content == 'timer_off';
      bool isTimerOn = message.content.startsWith('timer_on_');

      String mainText = '';
      String actionText = '\nChange timer';

      final senderName = message.sender?.name ?? "Someone";

      if (isTimerOff) {
        mainText = '$senderName turned off disappearing messages.';
      } else if (isTimerOn) {
        final secString = message.content.split('_').last;
        final sec = int.tryParse(secString) ?? 0;

        // ignore: unnecessary_brace_in_string_interps
        String timeStr = '${sec} seconds';
        if (sec >= 86400) {
          timeStr = '${sec ~/ 86400} days';
        } else if (sec >= 3600)
          // ignore: curly_braces_in_flow_control_structures
          timeStr = '${sec ~/ 3600} hours';
        else if (sec >= 60)
          // ignore: curly_braces_in_flow_control_structures
          timeStr = '${sec ~/ 60} minutes';

        mainText =
            '$senderName turned on disappearing messages. New messages will disappear from this chat $timeStr after they\'re sent, except when kept.';
      } else {
        mainText = displayMsg;
        actionText = '';
      }

      return Container(
        margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 24.w),
        alignment: Alignment.center,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 2.h),
                child: const Icon(
                  Icons.timer_outlined,
                  size: 16,
                  color: Colors.white70,
                ),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.white70,
                      height: 1.3,
                    ),
                    children: [
                      TextSpan(text: mainText),
                      if (actionText.isNotEmpty)
                        TextSpan(
                          text: actionText,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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

    String contentx = message.content;
    bool isExplicitAudio = false;
    bool isExplicitImage = false;
    if (content.startsWith('[AUDIO]')) {
      isExplicitAudio = true;
      contentx = content.substring(7); // Remove [AUDIO]
    } else if (content.startsWith('[IMAGE]')) {
      isExplicitImage = true;
      contentx = content.substring(7); // Remove [IMAGE]
    }

    final isMediax = isExplicitImage || (
        contentx.startsWith('http') &&
        (contentx.endsWith('.jpg') ||
            contentx.endsWith('.png') ||
            contentx.endsWith('.jpeg') ||
            contentx.endsWith('.gif')));

    bool isAudio =
        isExplicitAudio ||
        contentx.toLowerCase().endsWith('.m4a') ||
        contentx.toLowerCase().endsWith('.mp3') ||
        contentx.toLowerCase().endsWith('.wav') ||
        contentx.toLowerCase().endsWith('.aac');

    Widget contentWidget;
    bool isOnlyEmojiMsg = false;

    if (isAudio) {
      contentWidget = AudioBubbleWidget(
        audioUrl: contentx,
        isMe: isMe,
        isUploading: message.isUploading,
        uploadProgress: message.uploadProgress,
        duration: message.duration,
      );
    } else if (message.isLocalFile) {
      contentWidget = Stack(
        alignment: Alignment.center,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FullScreenImageViewer(
                    imageUrl: contentx,
                    isLocalFile: true,
                  ),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: Hero(
                tag: contentx,
                child: Image.file(
                  File(contentx),
                  width: 200.w,
                  height: 200.h,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          if (message.isUploading)
            Container(
              width: 50.w,
              height: 50.w,
              decoration: BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: message.uploadProgress,
                    color: Colors.white,
                  ),
                  Text(
                    "${(message.uploadProgress * 100).toInt()}%",
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ],
              ),
            ),
        ],
      );
    } else if (isMediax) {
      bool isVideo =
          contentx.toLowerCase().endsWith('.mp4') ||
          contentx.toLowerCase().endsWith('.mov');
      if (isVideo) {
        contentWidget = Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 250.w,
              height: 140.h,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8.r),
                image: const DecorationImage(
                  // Use a placeholder or thumbnail if available
                  image: NetworkImage("https://via.placeholder.com/250x140.png?text=Video"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Container(
              width: 250.w,
              height: 140.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.r),
                color: Colors.black.withOpacity(0.3),
              ),
            ),
            Icon(
              Icons.play_circle_fill,
              color: Colors.white,
              size: 48.w,
            ),
            if (message.duration != null && message.duration! > 0)
              Positioned(
                bottom: 8.h,
                right: 8.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    "${message.duration! ~/ 60}:${(message.duration! % 60).toString().padLeft(2, '0')}",
                    style: TextStyle(color: Colors.white, fontSize: 10.sp),
                  ),
                ),
              ),
          ],
        );
      } else {
        contentWidget = GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FullScreenImageViewer(
                  imageUrl: contentx,
                  isLocalFile: false,
                ),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: Hero(
              tag: contentx,
              child: Image.network(
                contentx,
                width: 200.w,
                height: 200.h,
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      }
    } else {
      if (content.isNotEmpty) {
        final str = content.replaceAll(RegExp(r'\s+'), '');
        if (str.isNotEmpty) {
          final RegExp emojiRegex = RegExp(
            r'^(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff])+$',
          );
          isOnlyEmojiMsg = emojiRegex.hasMatch(str);
        }
      }

      contentWidget = Text(
        content,
        style: TextStyle(
          color: isOnlyEmojiMsg
              ? null
              : Colors.white,
          fontSize: isOnlyEmojiMsg ? 40.sp : 15.sp,
        ),
      );
    }

    final chatCtrl = Get.find<ChatController>();

    Widget bubbleContent = Obx(() {
      final isHighlighted = chatCtrl.highlightedMessageId.value == message.id;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: EdgeInsets.only(
          bottom: 2.h,
          left: isMe ? 50.w : 0,
          right: isMe ? 0 : 50.w,
        ),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isOnlyEmojiMsg
              ? Colors.transparent
              : (isHighlighted
                    ? Colors.orange.withOpacity(0.5)
                    : (isMe ? const Color(0xFF3B82F6) : Colors.white.withOpacity(0.1))), // Dark theme bubble
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.r),
            topRight: Radius.circular(16.r),
            bottomLeft: isMe ? Radius.circular(16.r) : Radius.circular(0),
            bottomRight: isMe ? Radius.circular(0) : Radius.circular(16.r),
          ),
          border: isOnlyEmojiMsg
              ? null
              : (isHighlighted
                    ? Border.all(color: Colors.orange, width: 2)
                    : null),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.replyTo != null)
              GestureDetector(
                onTap: () {
                  bool found = chatCtrl.highlightMessage(message.replyTo!.id);
                  if (!found) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Message is too old and not loaded yet.')),
                    );
                  }
                },
                child: Container(
                  margin: EdgeInsets.only(bottom: 8.h),
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(isMe ? 0.1 : 0.05),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border(
                      left: BorderSide(
                        color: isMe ? Colors.white : const Color(0xFF3B82F6),
                        width: 4.w,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.replyTo!.sender?.name ?? 'Unknown',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.sp,
                          color: isMe ? Colors.white : AppTheme.primaryBlue,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        message.replyTo!.content,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.white70,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            contentWidget,
            SizedBox(height: 4.h),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.expiresAt != null)
                  Padding(
                    padding: EdgeInsets.only(right: 6.w),
                    child: CountdownWidget(
                      expiresAt: message.expiresAt!,
                      style: TextStyle(
                        color: isOnlyEmojiMsg
                            ? Colors.grey
                            : Colors.white70,
                        fontSize: 10.sp,
                      ),
                    ),
                  ),
                if (message.createdAt != null)
                  Text(
                    DateFormat('hh:mm a').format(message.createdAt!.toLocal()),
                    style: TextStyle(
                      color: isOnlyEmojiMsg
                          ? Colors.grey
                          : Colors.white70,
                      fontSize: 10.sp,
                    ),
                  ),
                if (isMe) ...[
                  SizedBox(width: 4.w),
                  if (message.isUploading)
                    Icon(
                      Icons.access_time,
                      size: 14.sp,
                      color: isOnlyEmojiMsg ? Colors.grey : Colors.white70,
                    )
                  else if (message.readBy.isNotEmpty)
                    Icon(
                      Icons.done_all,
                      size: 16.sp,
                      color: isOnlyEmojiMsg ? Colors.green : Colors.greenAccent,
                    )
                  else if (message.deliveredTo.isNotEmpty)
                    Icon(
                      Icons.done_all,
                      size: 16.sp,
                      color: isOnlyEmojiMsg ? Colors.grey : Colors.white54,
                    )
                  else
                    Icon(
                      Icons.done,
                      size: 16.sp,
                      color: isOnlyEmojiMsg ? Colors.grey : Colors.white54,
                    ),
                ],
              ],
            ),
          ],
        ),
      );
    });

    Widget bubbleWithReactions = message.reactions.isNotEmpty
        ? Stack(
            clipBehavior: Clip.none,
            children: [
              bubbleContent,
              Positioned(
                bottom: -10.h,
                left: isMe ? null : 20.w,
                right: isMe ? 20.w : null,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2B333E), // Dark bubble for reactions
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.black12, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: message.reactions.map<Widget>((r) {
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: 2.w),
                        child: _renderReactionEmoji(
                          r['emoji'] ?? r['reaction'] ?? '',
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          )
        : bubbleContent;

    return Dismissible(
      key: Key(message.id),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (direction) async {
        Get.find<ChatController>().setReplyTo(message);
        return false;
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(left: 20.w),
        child: const Icon(Icons.reply, color: Colors.grey),
      ),
      child: GestureDetector(
        onLongPress: () => _showOptions(context),
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: message.reactions.isNotEmpty ? 16.h : 8.h,
            ),
            child: bubbleWithReactions,
          ),
        ),
      ),
    );
  }

  Widget _renderReactionEmoji(String emojiId) {
    final Map<String, AnimatedEmojiData> emojiMap = {
      AnimatedEmojis.heart.id: AnimatedEmojis.heart,
      AnimatedEmojis.thumbsUp.id: AnimatedEmojis.thumbsUp,
      AnimatedEmojis.laughing.id: AnimatedEmojis.laughing,
      AnimatedEmojis.sad.id: AnimatedEmojis.sad,
      AnimatedEmojis.fire.id: AnimatedEmojis.fire,
      AnimatedEmojis.rocket.id: AnimatedEmojis.rocket,
      AnimatedEmojis.star.id: AnimatedEmojis.star,
      AnimatedEmojis.clap.id: AnimatedEmojis.clap,
      AnimatedEmojis.kiss.id: AnimatedEmojis.kiss,
      AnimatedEmojis.mindBlown.id: AnimatedEmojis.mindBlown,
      AnimatedEmojis.cool.id: AnimatedEmojis.cool,
      AnimatedEmojis.poop.id: AnimatedEmojis.poop,
    };

    if (emojiId.isNotEmpty) {
      if (emojiMap.containsKey(emojiId)) {
        return AnimatedEmoji(emojiMap[emojiId]!, size: 18.w);
      } else {
        // If it's a standard unicode emoji instead of an ID
        return Text(emojiId, style: TextStyle(fontSize: 14.sp));
      }
    }
    return Text('👍', style: TextStyle(fontSize: 14.sp));
  }
}

class AudioBubbleWidget extends StatefulWidget {
  final String audioUrl;
  final bool isMe;
  final bool isUploading;
  final double uploadProgress;
  final int? duration;

  const AudioBubbleWidget({
    Key? key,
    required this.audioUrl,
    required this.isMe,
    this.isUploading = false,
    this.uploadProgress = 0.0,
    this.duration,
  }) : super(key: key);

  @override
  State<AudioBubbleWidget> createState() => _AudioBubbleWidgetState();
}

class _AudioBubbleWidgetState extends State<AudioBubbleWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    if (widget.duration != null) {
      _duration = Duration(seconds: widget.duration!);
    }
    _initAudio();
  }

  @override
  void didUpdateWidget(covariant AudioBubbleWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.audioUrl != oldWidget.audioUrl ||
        (oldWidget.isUploading && !widget.isUploading)) {
      _initAudio();
    }
  }

  void _initAudio() async {
    if (!widget.isUploading) {
      try {
        if (widget.audioUrl.startsWith('http')) {
          await _audioPlayer.setSourceUrl(widget.audioUrl);
        } else {
          await _audioPlayer.setSourceDeviceFile(widget.audioUrl);
        }
      } catch (e) {
        debugPrint('Error loading audio source: $e');
      }
    }

    _audioPlayer.onPlayerStateChanged.listen((state) async {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
        if (state == PlayerState.playing && _duration == Duration.zero) {
          final d = await _audioPlayer.getDuration();
          if (d != null && mounted) {
            setState(() {
              _duration = d;
            });
          }
        }
      }
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) {
        setState(() {
          _duration = newDuration;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted && !_isDragging) {
        setState(() {
          _position = newPosition;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220.w,
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () async {
              if (widget.isUploading) return;
              if (_isPlaying) {
                await _audioPlayer.pause();
              } else {
                if (_position == Duration.zero || _position >= _duration) {
                  if (widget.audioUrl.startsWith('http')) {
                    await _audioPlayer.play(UrlSource(widget.audioUrl));
                  } else {
                    await _audioPlayer.play(DeviceFileSource(widget.audioUrl));
                  }
                } else {
                  await _audioPlayer.resume();
                }
              }
            },
            child: CircleAvatar(
              radius: 18.r,
              backgroundColor: widget.isMe ? Colors.white : AppTheme.primaryBlue,
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: widget.isMe ? AppTheme.primaryBlue : Colors.white,
                size: 24.sp,
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 24.h,
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 3.h,
                      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.r),
                      overlayShape: RoundSliderOverlayShape(overlayRadius: 12.r),
                      activeTrackColor: widget.isMe
                          ? Colors.white
                          : AppTheme.primaryBlue,
                      inactiveTrackColor: widget.isMe
                          ? Colors.white54
                          : AppTheme.primaryBlue.withOpacity(0.2),
                      thumbColor: widget.isMe
                          ? Colors.white
                          : AppTheme.primaryBlue,
                    ),
                    child: Slider(
                      min: 0.0,
                      max: _duration.inSeconds > 0
                          ? _duration.inSeconds.toDouble()
                          : 1.0,
                      value: _position.inSeconds.toDouble().clamp(
                        0.0,
                        _duration.inSeconds > 0
                            ? _duration.inSeconds.toDouble()
                            : 1.0,
                      ),
                      onChangeStart: (val) {
                        setState(() => _isDragging = true);
                      },
                      onChanged: (val) {
                        setState(() {
                          _position = Duration(seconds: val.toInt());
                        });
                      },
                      onChangeEnd: (val) {
                        if (!widget.isUploading) {
                          _audioPlayer.seek(Duration(seconds: val.toInt()));
                        }
                        setState(() => _isDragging = false);
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(_position),
                        style: TextStyle(
                          color: widget.isMe ? Colors.white70 : Colors.grey[500],
                          fontSize: 10.sp,
                        ),
                      ),
                      if (widget.isUploading)
                        SizedBox(
                          width: 10.w,
                          height: 10.w,
                          child: CircularProgressIndicator(
                            value: widget.uploadProgress,
                            color: widget.isMe
                                ? Colors.white
                                : AppTheme.primaryBlue,
                            strokeWidth: 2,
                          ),
                        )
                      else
                        Text(
                          _formatDuration(_duration),
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10.sp,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
