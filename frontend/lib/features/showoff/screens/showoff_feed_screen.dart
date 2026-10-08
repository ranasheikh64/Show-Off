import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../controllers/showoff_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../chat/services/socket_service.dart';
import '../../chat/controllers/chat_controller.dart';
import '../widgets/showoff_empty_state.dart';
import '../widgets/showoff_fabs.dart';
import '../widgets/showoff_header.dart';
import '../widgets/showoff_post_card.dart';
import 'create_showoff_screen.dart';

class ShowOffFeedScreen extends StatefulWidget {
  const ShowOffFeedScreen({Key? key}) : super(key: key);

  @override
  State<ShowOffFeedScreen> createState() => _ShowOffFeedScreenState();
}

class _ShowOffFeedScreenState extends State<ShowOffFeedScreen> {
  final ShowOffController _showOffCtrl = Get.put(ShowOffController());
  final AuthController _authCtrl = Get.find<AuthController>();
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> _fabVisible = ValueNotifier(true);
  bool _showMyPosts = false;
  bool _paginationLocked = false; // throttle pagination
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_paginationLocked) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      _paginationLocked = true;
      (_showMyPosts
              ? _showOffCtrl.fetchMyPosts()
              : _showOffCtrl.fetchFeed())
          .whenComplete(() => _paginationLocked = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fabVisible.dispose();
    super.dispose();
  }

  bool _onScrollNotification(ScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    if (n is ScrollStartNotification || n is ScrollUpdateNotification) {
      _fabVisible.value = false;
    } else if (n is ScrollEndNotification) {
      _fabVisible.value = true;
    }
    return false;
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
      );
  }

  Future<void> _chooseUser(String targetUserId) async {
    final newlyChosen = await _showOffCtrl.chooseUser(targetUserId);
    if (!mounted) return;
    if (newlyChosen == null) {
      return _toast('Could not send love. Please try again.');
    }
    if (!newlyChosen) return _toast('You have already shown love to this person ✅');

    SocketService.emitWithAck('access_chat', {'userId': targetUserId}, (res) {
      if (!mounted) return;
      final success = res is Map && res['success'] == true;
      if (success) {
        Get.find<ChatController>().sendMessage(
          res['chat']['_id'],
          'Sending love from Show Off! ❤️',
        );
      } else {
        _toast('Loved, but the message could not be sent.');
      }
    });
  }

  void _messageUser(String targetUserId, String targetUserName) {
    SocketService.emitWithAck('access_chat', {'userId': targetUserId}, (res) {
      if (!mounted) return;
      if (res is Map && res['success'] == true) {
        context.push('/chat/${res['chat']['_id']}', extra: targetUserName);
      } else {
        _toast(
          (res is Map ? res['message'] : null) ??
              'Could not open the chat. Please try again.',
        );
      }
    });
  }

  Future<void> _confirmDelete(String postId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete post?'),
        content: const Text('This post will be removed permanently.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) _showOffCtrl.deletePost(postId);
  }

  void _onToggle(bool value) {
    setState(() => _showMyPosts = value);
    if (value && _showOffCtrl.myPosts.isEmpty)
      _showOffCtrl.fetchMyPosts(refresh: true);
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  Future<void> _refresh() => _showMyPosts
      ? _showOffCtrl.fetchMyPosts(refresh: true)
      : _showOffCtrl.fetchFeed(refresh: true);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0C1F),
      body: SafeArea(
        child: Column(
          children: [
            ShowOffHeader(
              showMyPosts: _showMyPosts,
              onChanged: _onToggle,
              onSearch: _onSearchChanged,
            ),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: _onScrollNotification,
                child: Obx(_buildBody),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: ValueListenableBuilder<bool>(
        valueListenable: _fabVisible,
        builder: (_, visible, __) => Obx(
          () => ShowOffFabs(
            visible: visible,
            unreadCount: Get.find<ChatController>().unreadChatCount,
            onChats: () => context.push('/chat-list'),
            onAddPost: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateShowOffScreen()),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    var posts = _showMyPosts ? _showOffCtrl.myPosts : _showOffCtrl.feedPosts;
    
    if (_searchQuery.isNotEmpty) {
      posts = posts.where((p) {
        final name = p.user?.name.toLowerCase() ?? '';
        final username = p.user?.username.toLowerCase() ?? '';
        final email = p.user?.email.toLowerCase() ?? '';
        return name.contains(_searchQuery) || username.contains(_searchQuery) || email.contains(_searchQuery);
      }).toList().obs;
    }

    final loading = _showMyPosts
        ? _showOffCtrl.isLoadingMyPosts.value
        : _showOffCtrl.isLoadingFeed.value;
    final bool hasSearchOrFilter = _showOffCtrl.currentFilters.isNotEmpty || _searchQuery.isNotEmpty;

    if (posts.isEmpty) {
      return loading
          ? const Center(child: CircularProgressIndicator())
          : ShowOffEmptyState(
              isMyPosts: _showMyPosts,
              isFiltering: hasSearchOrFilter,
            );
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 150),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        itemCount: posts.length + (loading ? 1 : 0),
        addRepaintBoundaries: false, // we add manually per card
        itemBuilder: (_, i) {
          if (i == posts.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final post = posts[i];
          return RepaintBoundary(
            key: ValueKey(post.id),
            child: ShowOffPostCard(
              post: post,
              isMine: post.user?.id == _authCtrl.currentUser.value?.id,
              onChoose: () => _chooseUser(post.user!.id),
              onMessage: () => _messageUser(post.user!.id, post.user!.name),
              onDelete: () => _confirmDelete(post.id),
            ),
          );
        },
      ),
    );
  }
}
