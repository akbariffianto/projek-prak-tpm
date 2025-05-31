import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/review_model.dart';
import '../models/bookmark_model.dart';
import '../models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HiveService {
  static final HiveService _instance = HiveService._internal();

  factory HiveService() => _instance;

  HiveService._internal();

  Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(ReviewModelAdapter());
    Hive.registerAdapter(BookmarkModelAdapter());
    Hive.registerAdapter(UserModelAdapter());

    await Hive.openBox<ReviewModel>('reviews');
    await Hive.openBox<BookmarkModel>('bookmarks');
    await Hive.openBox<UserModel>('users');
  }

  // Review
  Box<ReviewModel> get reviewBox => Hive.box<ReviewModel>('reviews');

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

  // Bookmark
  Box<BookmarkModel> get bookmarkBox => Hive.box<BookmarkModel>('bookmarks');

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

  // User
  Box<UserModel> get userBox => Hive.box<UserModel>('users');

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

  Future<void> updateUser(UserModel user) async {
    await user.save();
  }

  Future<void> deleteUser(UserModel user) async {
    await user.delete();
  }

  // Login sederhana: cari user berdasar username dan password
  UserModel? login(String username, String password) {
    try {
      return userBox.values
          .firstWhere((u) => u.username == username && u.password == password);
    } catch (e) {
      return null;
    }
  }

  Future<void> saveUserSession(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('userId', userId);
  }

  // Ambil userId yang login, null jika belum login
  Future<int?> getUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }

  // Hapus session (logout)
  Future<void> clearUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
  }
}
