import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'dart:io';

import '../../../core/constants/app_theme.dart';
import '../controllers/chat_controller.dart';

class ChatInputWidget extends StatefulWidget {
  final String chatId;
  const ChatInputWidget({super.key, required this.chatId});

  @override
  State<ChatInputWidget> createState() => _ChatInputWidgetState();
}

class _ChatInputWidgetState extends State<ChatInputWidget> {
  final ChatController _chatCtrl = Get.find<ChatController>();
  final TextEditingController _msgCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ImagePicker _picker = ImagePicker();

  bool _isTyping = false;
  bool _showEmojiPicker = false;
  
  bool _isRecording = false;
  bool _isRecordingCompleted = false;
  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _recordFilePath;
  Timer? _recordTimer;
  int _recordSeconds = 0;

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  int _playbackPosition = 0;

  @override
  void initState() {
    super.initState();
    _msgCtrl.addListener(() {
      setState(() {
        _isTyping = _msgCtrl.text.trim().isNotEmpty;
      });
    });
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() {
          _showEmojiPicker = false;
        });
      }
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          if (state == PlayerState.completed) {
            _playbackPosition = 0;
            _isPlaying = false;
          }
        });
      }
    });
    _audioPlayer.onPositionChanged.listen((pos) {
      if (mounted) {
        setState(() => _playbackPosition = pos.inSeconds);
      }
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _focusNode.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _recordTimer?.cancel();
    super.dispose();
  }

  void _send() {
    if (_msgCtrl.text.trim().isNotEmpty) {
      _chatCtrl.sendMessage(widget.chatId, _msgCtrl.text.trim());
      _msgCtrl.clear();
    }
  }

  void _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _chatCtrl.sendMediaMessage(widget.chatId, image.path);
    }
  }

  void _startRecording() async {
    if (_isRecording) return;
    try {
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Microphone access is required", style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (await _audioRecorder.hasPermission()) {
        final dir = await getApplicationDocumentsDirectory();
        _recordFilePath = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder.start(const RecordConfig(), path: _recordFilePath!);
        
        _recordTimer?.cancel();
        setState(() {
          _isRecording = true;
          _isRecordingCompleted = false;
          _recordSeconds = 0;
          _playbackPosition = 0;
        });
        _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _recordSeconds++;
          });
        });
      }
    } catch (e) {
      print("Error starting recording: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to start recording", style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.red,
          ),
        );
      }
      _deleteRecording();
    }
  }

  void _stopRecording(bool sendImmediately) async {
    try {
      final path = await _audioRecorder.stop();
      _recordTimer?.cancel();
      
      if (mounted) {
        setState(() {
          _isRecording = false;
        });
      }

      if (_recordSeconds < 1) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Recording too short", style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 1),
            ),
          );
        }
        _deleteRecording();
        return;
      }

      if (mounted) {
        setState(() {
          if (path != null) {
            _recordFilePath = path;
            _isRecordingCompleted = true;
          }
        });
      }
      
      if (sendImmediately && path != null) {
        _sendAudio();
      }
    } catch (e) {
      print("Error stopping recording: $e");
      _deleteRecording();
    }
  }

  void _sendAudio() {
    if (_recordFilePath != null) {
      _chatCtrl.sendMediaMessage(widget.chatId, _recordFilePath!, isAudio: true, duration: _recordSeconds);
      _deleteRecording();
    }
  }

  void _deleteRecording() async {
    try {
      _audioPlayer.stop();
      _recordTimer?.cancel();
      
      if (_isRecording) {
        await _audioRecorder.stop();
      }
    } catch (e) {
      print("Error deleting recording: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isRecording = false;
          _isRecordingCompleted = false;
          _recordFilePath = null;
          _recordSeconds = 0;
          _playbackPosition = 0;
        });
      }
    }
  }

  void _onEmojiSelected(Category? category, Emoji emoji) {
    _msgCtrl.text = _msgCtrl.text + emoji.emoji;
  }

  void _onBackspacePressed() {
    if (_msgCtrl.text.isNotEmpty) {
      _msgCtrl
        ..text = _msgCtrl.text.characters.skipLast(1).toString()
        ..selection = TextSelection.fromPosition(
            TextPosition(offset: _msgCtrl.text.length));
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final replyMsg = _chatCtrl.replyToMessage.value;
      
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (replyMsg != null)
              Container(
                margin: EdgeInsets.only(bottom: 8.h),
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border(left: BorderSide(color: AppTheme.primaryBlue, width: 4.w)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(replyMsg.sender?.name ?? 'Unknown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.sp, color: AppTheme.primaryBlue)),
                          SizedBox(height: 2.h),
                          Text(replyMsg.content, style: TextStyle(fontSize: 12.sp, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16, color: Colors.black54),
                      onPressed: () => _chatCtrl.setReplyTo(null),
                    ),
                  ],
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!_isRecording && !_isRecordingCompleted)
                  Padding(
                    padding: EdgeInsets.only(right: 8.w, bottom: 8.h),
                    child: GestureDetector(
                      onTap: () {
                        if (_showEmojiPicker) {
                          _focusNode.requestFocus();
                        } else {
                          FocusScope.of(context).unfocus();
                        }
                        setState(() {
                          _showEmojiPicker = !_showEmojiPicker;
                        });
                      },
                      child: Icon(
                        _showEmojiPicker ? Icons.keyboard : Icons.sentiment_satisfied_alt,
                        color: Colors.grey[600],
                        size: 26.w,
                      ),
                    ),
                  ),
                if (_isRecording || _isRecordingCompleted)
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red, size: 24.w),
                    onPressed: _deleteRecording,
                  ),
                Expanded(
                  child: _isRecording
                      ? Container(
                          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F4FA),
                            borderRadius: BorderRadius.circular(24.r),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.mic, color: Colors.red, size: 20.w),
                              SizedBox(width: 8.w),
                              Text(
                                "Recording... ${_formatDuration(_recordSeconds)}",
                                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.red),
                              ),
                            ],
                          ),
                        )
                      : _isRecordingCompleted
                          ? Container(
                              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F4FA),
                                borderRadius: BorderRadius.circular(24.r),
                              ),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      if (_isPlaying) {
                                        _audioPlayer.pause();
                                      } else if (_recordFilePath != null) {
                                        _audioPlayer.play(DeviceFileSource(_recordFilePath!));
                                      }
                                    },
                                    child: Icon(
                                      _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                                      color: AppTheme.primaryBlue,
                                      size: 30.w,
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: Text(
                                      _isPlaying ? _formatDuration(_playbackPosition) : _formatDuration(_recordSeconds),
                                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.black87),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4F6F9),
                                borderRadius: BorderRadius.circular(24.r),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _msgCtrl,
                                      focusNode: _focusNode,
                                      minLines: 1,
                                      maxLines: 4,
                                      textCapitalization: TextCapitalization.sentences,
                                      style: TextStyle(fontSize: 15.sp),
                                      decoration: InputDecoration(
                                        hintText: 'Type a message...',
                                        hintStyle: TextStyle(color: Colors.grey[500], fontSize: 15.sp),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(right: 8.w, bottom: 4.h),
                                    child: IconButton(
                                      icon: Icon(Icons.attach_file, color: Colors.grey[600], size: 24.w),
                                      onPressed: _pickImage,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                ),
                SizedBox(width: 12.w),
                Padding(
                  padding: EdgeInsets.only(bottom: 2.h),
                  child: GestureDetector(
                    onLongPressStart: (_) {
                      if (!_isTyping && !_isRecordingCompleted) {
                        _startRecording();
                      }
                    },
                    onLongPressEnd: (_) {
                      if (_isRecording) {
                        _stopRecording(false);
                      }
                    },
                    onLongPressCancel: () {
                      if (_isRecording) {
                        _stopRecording(false);
                      }
                    },
                    onTap: () {
                      if (_isTyping) {
                        _send();
                      } else if (_isRecordingCompleted) {
                        _sendAudio();
                      } else {
                        // Quick tap on mic without holding
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Hold to record audio.", style: TextStyle(color: Colors.white)),
                            backgroundColor: Colors.orange,
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                    child: CircleAvatar(
                      backgroundColor: _isRecordingCompleted || _isTyping ? AppTheme.primaryBlue : AppTheme.primaryBlue,
                      radius: 24.r,
                      child: Icon(
                        _isRecordingCompleted || _isTyping ? Icons.send : (_isRecording ? Icons.mic : Icons.mic_none),
                        color: Colors.white,
                        size: 26.w,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_showEmojiPicker)
              SizedBox(
                height: 250.h,
                child: EmojiPicker(
                  onEmojiSelected: _onEmojiSelected,
                  onBackspacePressed: _onBackspacePressed,
                  config: Config(
                    emojiViewConfig: EmojiViewConfig(
                      backgroundColor: Colors.white,
                      columns: 7,
                      emojiSizeMax: 28 * (Platform.isIOS ? 1.3 : 1.0),
                    ),
                    categoryViewConfig: const CategoryViewConfig(
                      backgroundColor: Colors.white,
                      dividerColor: Colors.transparent,
                      indicatorColor: AppTheme.primaryBlue,
                      iconColorSelected: AppTheme.primaryBlue,
                      iconColor: Colors.grey,
                    ),
                    bottomActionBarConfig: const BottomActionBarConfig(
                      showBackspaceButton: true,
                      showSearchViewButton: false,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}
