import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/review_model.dart';
import '../models/bookmark_model.dart';
import '../models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HiveService {
  static const String userBoxName = 'users';
  static const String reviewBoxName = 'reviews';
  static const String bookmarkBoxName = 'bookmarks';

  static final HiveService _instance = HiveService._internal();
  factory HiveService() => _instance;
  HiveService._internal();

  Future<void> init() async {
    await Hive.initFlutter();

    // === PENDAFTARAN ADAPTOR ===
    Hive.registerAdapter(ReviewModelAdapter());
    Hive.registerAdapter(BookmarkModelAdapter());
    Hive.registerAdapter(UserModelAdapter());

    // === PEMBUKAAN BOX ===
    await Hive.openBox<ReviewModel>(reviewBoxName);
    await Hive.openBox<BookmarkModel>(bookmarkBoxName);
    await Hive.openBox<UserModel>(userBoxName);
  }

  // Review methods
  Box<ReviewModel> get reviewBox => Hive.box<ReviewModel>(reviewBoxName);

  Future<void> addReview(ReviewModel review) async {
    await reviewBox.add(review);
  }

  List<ReviewModel> getReviewsByUser(int userId) {
    return reviewBox.values.where((r) => r.userId == userId).toList();
  }

  Future<void> updateReview(ReviewModel review) async {
    await review.save();
  }

  Future<void> deleteReview(ReviewModel review) async {
    await review.delete();
  }

  // Bookmark methods
  Box<BookmarkModel> get bookmarkBox => Hive.box<BookmarkModel>(bookmarkBoxName);

  Future<void> addBookmark(BookmarkModel bookmark) async {
    await bookmarkBox.add(bookmark);
  }

  List<BookmarkModel> getBookmarksByUser(int userId) {
    return bookmarkBox.values.where((b) => b.userId == userId).toList();
  }

  Future<void> deleteBookmark(BookmarkModel bookmark) async {
    await bookmark.delete();
  }

  bool isBookmarked(int userId, int characterId) {
    return bookmarkBox.values
        .any((b) => b.userId == userId && b.characterId == characterId);
  }

  Map<int, int> getBookmarkCounts() {
    final bookmarkCounts = <int, int>{};
    for (var bookmark in bookmarkBox.values) {
      bookmarkCounts[bookmark.characterId] =
          (bookmarkCounts[bookmark.characterId] ?? 0) + 1;
    }
    return bookmarkCounts;
  }

  // User methods
  Box<UserModel> get userBox => Hive.box<UserModel>(userBoxName);

  Future<int> addUser(UserModel user) async {
    return await userBox.add(user);
  }

  UserModel? getUserByUsername(String username) {
    try {
      return userBox.values.firstWhere((u) => u.username == username);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateUser(int userId, {
    String? username,
    String? profilePhotoPath,
    String? description,
  }) async {
    try {
      final user = userBox.values.firstWhere(
        (u) => u.id == userId,
      );
      
      if (username != null) user.username = username;
      if (profilePhotoPath != null) user.profilePhotoPath = profilePhotoPath;
      if (description != null) user.description = description;
      
      await user.save();
    } catch (e) {
      debugPrint('Error updating user: $e');
      throw Exception('Failed to update user');
    }
  }

  Future<void> deleteUser(int userId) async {
    try {
      final user = userBox.values.firstWhere(
        (u) => u.id == userId,
      );
      await user.delete();
      await logout();
    } catch (e) {
      debugPrint('Error deleting user: $e');
      throw Exception('Failed to delete user');
    }
  }

  UserModel? login(String username, String password) {
    try {
      return userBox.values
          .firstWhere((u) => u.username == username && u.password == password);
    } catch (e) {
      return null;
    }
  }

  // Session management
  Future<void> saveUserSession(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('userId', userId);
  }

  Future<int?> getUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }

  Future<void> clearUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
  }

  Future<void> logout() async {
    await clearUserSession();
  }
}