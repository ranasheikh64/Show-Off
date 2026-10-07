import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:dio/dio.dart';

import '../models/showoff_model.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_url.dart';

class ShowOffController extends GetxController {
  final Dio _apiService = DioClient.instance;

  var feedPosts = <ShowOffModel>[].obs;
  var myPosts = <ShowOffModel>[].obs;
  var isLoadingFeed = false.obs;
  var isLoadingMyPosts = false.obs;
  var isUploading = false.obs;
  var uploadProgress = 0.0.obs;

  var currentFeedPage = 1;
  var hasMoreFeed = true;

  var currentMyPostsPage = 1;
  var hasMoreMyPosts = true;

  @override
  void onInit() {
    super.onInit();
    fetchFeed();
  }

  Future<void> fetchFeed({bool refresh = false}) async {
    if (refresh) {
      currentFeedPage = 1;
      hasMoreFeed = true;
      feedPosts.clear();
    }
    if (!hasMoreFeed || isLoadingFeed.value) return;

    isLoadingFeed.value = true;
    try {
      final response = await _apiService.get(
        ApiUrl.showOffFeed,
        queryParameters: {
          'page': currentFeedPage,
          'limit': 10,
          'myPosts': false,
        },
      );
      if (response.data['success']) {
        final List<dynamic> data = response.data['posts'];
        final newPosts = data.map((e) => ShowOffModel.fromJson(e)).toList();

        if (newPosts.isEmpty) {
          hasMoreFeed = false;
        } else {
          feedPosts.addAll(newPosts);
          currentFeedPage++;
        }
      }
    } catch (e) {
      print('Error fetching feed: $e');
    } finally {
      isLoadingFeed.value = false;
    }
  }

  Future<void> fetchMyPosts({bool refresh = false}) async {
    if (refresh) {
      currentMyPostsPage = 1;
      hasMoreMyPosts = true;
      myPosts.clear();
    }
    if (!hasMoreMyPosts || isLoadingMyPosts.value) return;

    isLoadingMyPosts.value = true;
    try {
      final response = await _apiService.get(
        ApiUrl.showOffFeed,
        queryParameters: {
          'page': currentMyPostsPage,
          'limit': 10,
          'myPosts': true,
        },
      );
      if (response.data['success']) {
        final List<dynamic> data = response.data['posts'];
        final newPosts = data.map((e) => ShowOffModel.fromJson(e)).toList();

        if (newPosts.isEmpty) {
          hasMoreMyPosts = false;
        } else {
          myPosts.addAll(newPosts);
          currentMyPostsPage++;
        }
      }
    } catch (e) {
      print('Error fetching my posts: $e');
    } finally {
      isLoadingMyPosts.value = false;
    }
  }

  Future<bool> createPost(List<String> filePaths) async {
    isUploading.value = true;
    uploadProgress.value = 0.0;
    try {
      List<String> uploadedUrls = [];
      for (int i = 0; i < filePaths.length; i++) {
        final fileName = filePaths[i].split('/').last;
        final formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(
            filePaths[i],
            filename: fileName,
          ),
        });

        final response = await _apiService.post(
          ApiUrl.uploadMedia,
          data: formData,
          onSendProgress: (count, total) {
            uploadProgress.value =
                (i / filePaths.length) +
                ((count / total) * (1 / filePaths.length));
          },
        );
        uploadedUrls.add(response.data['url']);
      }

      final response = await _apiService.post(
        ApiUrl.showOff,
        data: {'images': uploadedUrls},
      );
      if (response.data['success']) {
        final newPost = ShowOffModel.fromJson(response.data['data']);
        myPosts.insert(0, newPost);
        // Also add to feed if they are browsing "All" feed that includes their own posts.
        // Wait, the backend explicitly filtered out "myPosts" depending on the query param!
        return true;
      }
      return false;
    } catch (e) {
      print('Error creating post: $e');
      return false;
    } finally {
      isUploading.value = false;
      uploadProgress.value = 0.0;
    }
  }

  /// Returns true if newly chosen, false if already chosen, null on failure.
  Future<bool?> chooseUser(String userId) async {
    try {
      final response = await _apiService.post(
        ApiUrl.showOffChoose,
        data: {'userId': userId},
      );
      if (response.data['success'] != true) return null;
      _markUserChosen(userId);
      return response.data['alreadyChosen'] != true;
    } catch (e) {
      print('Error choosing user: $e');
      return null;
    }
  }

  void _markUserChosen(String userId) {
    for (final list in [feedPosts, myPosts]) {
      for (var i = 0; i < list.length; i++) {
        if (list[i].user?.id == userId) {
          list[i] = list[i].copyWith(isChosen: true);
        }
      }
    }
  }

  Future<bool> deletePost(String postId) async {
    try {
      final response = await _apiService.delete(ApiUrl.showOffById(postId));
      if (response.data['success']) {
        feedPosts.removeWhere((p) => p.id == postId);
        myPosts.removeWhere((p) => p.id == postId);
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting post: $e');
      return false;
    }
  }
}
