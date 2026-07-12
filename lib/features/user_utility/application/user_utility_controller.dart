import 'package:daily_meal_flutter_app/features/user_utility/data/user_utility_repository.dart';
import 'package:daily_meal_flutter_app/features/user_utility/domain/post_summary.dart';
import 'package:flutter/foundation.dart';
import 'package:daily_meal_flutter_app/features/auth/domain/app_user.dart';

class UserUtilityController extends ChangeNotifier {
  UserUtilityController(this._repository);
  final UserUtilityRepositoryContract _repository;
  PostSummaryFilter filter = PostSummaryFilter.all;
  List<SummaryPost> posts = const [], progressPosts = const [];
  int page = 1;
  bool hasMore = false, loading = false, loadingMore = false, busy = false;
  String? errorMessage;

  Future<void> loadSummary({PostSummaryFilter? selected}) async {
    if (selected != null) filter = selected;
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final result = await _repository.postSummary(filter);
      posts = result.posts;
      page = result.page;
      hasMore = result.hasMore;
    } catch (error) {
      errorMessage = error.toString();
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (!hasMore || loadingMore) return;
    loadingMore = true;
    notifyListeners();
    try {
      final result = await _repository.postSummary(filter, page: page + 1);
      final ids = posts.map((e) => e.id).toSet();
      posts = [...posts, ...result.posts.where((e) => !ids.contains(e.id))];
      page = result.page;
      hasMore = result.hasMore;
    } catch (error) {
      errorMessage = error.toString();
      rethrow;
    } finally {
      loadingMore = false;
      notifyListeners();
    }
  }

  Future<void> loadProgress(String userId) async {
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      progressPosts = await _repository.userPosts(userId);
    } catch (error) {
      errorMessage = error.toString();
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  String? validatePassword(String current, String next, String confirm) {
    if (current.length < 6) return 'Mật khẩu hiện tại cần ít nhất 6 ký tự.';
    if (next.length < 8) return 'Mật khẩu mới cần ít nhất 8 ký tự.';
    if (next != confirm) return 'Mật khẩu nhập lại chưa khớp.';
    return null;
  }

  Future<bool> changePassword(
    String current,
    String next,
    String confirm,
  ) async {
    final validation = validatePassword(current, next, confirm);
    if (validation != null) {
      errorMessage = validation;
      notifyListeners();
      return false;
    }
    busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _repository.changePassword(
        currentPassword: current,
        newPassword: next,
      );
      return true;
    } catch (error) {
      errorMessage = error.toString();
      rethrow;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<AppUser> linkGoogle(String idToken) async {
    busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      return await _repository.linkGoogle(idToken);
    } catch (error) {
      errorMessage = error.toString();
      rethrow;
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
