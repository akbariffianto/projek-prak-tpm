// Path: lib/pages/detail_page.dart
import 'package:flutter/material.dart';
import '../services/disney_service.dart';
import '../services/hive_service.dart';
import '../models/review_model.dart';
import '../models/bookmark_model.dart';
import '../models/user_model.dart'; // Import UserModel

class DetailPage extends StatefulWidget {
  final int characterId;

  const DetailPage({super.key, required this.characterId});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late Future<Map<String, dynamic>> _characterFuture;
  final TextEditingController _commentController = TextEditingController();
  double _rating = 3.0;
  double _averageRating = 0.0;
  int _totalReviews = 0;

  int? _currentUserId;
  List<ReviewModel> _characterReviews = [];
  Map<int, String> _usernames = {}; // Map untuk menyimpan userId ke username
  ReviewModel? _editingReview;

  final GlobalKey _reviewTextFieldKey = GlobalKey();

  bool _isBookmarked = false;
  bool _bookmarkLoading = true;

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    _characterFuture = DisneyService.fetchCharacterDetail(widget.characterId);
    _currentUserId = await HiveService().getUserSession();
    if (_currentUserId != null) {
      await _loadReviews();
      await _checkBookmarkStatus();
    } else {
      setState(() {
        _bookmarkLoading = false;
      });
    }
    setState(() {});
  }

  Future<void> _loadReviews() async {
    final allReviews = HiveService()
        .reviewBox
        .values
        .where((r) => r.characterId == widget.characterId)
        .toList();

    // Load all usernames for the reviews
    final Map<int, String> fetchedUsernames = {};
    for (var review in allReviews) {
      if (!fetchedUsernames.containsKey(review.userId)) {
        UserModel? user = HiveService().userBox.values.firstWhere(
              (u) => u.id == review.userId,
              orElse: () => throw Exception(
                  'User not found for review'), // Should not happen if data is consistent
            );
        if (user != null) {
          fetchedUsernames[user.id] = user.username;
        }
      }
    }

    final List<ReviewModel> myReviews = [];
    final List<ReviewModel> otherReviews = [];

    for (var review in allReviews) {
      if (_currentUserId != null && review.userId == _currentUserId) {
        myReviews.add(review);
      } else {
        otherReviews.add(review);
      }
    }

    myReviews.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    otherReviews.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    setState(() {
      _characterReviews = [...myReviews, ...otherReviews];
      _usernames = fetchedUsernames; // Simpan usernames yang sudah diambil
      _calculateAverageRating();
    });
  }

  void _calculateAverageRating() {
    if (_characterReviews.isEmpty) {
      _averageRating = 0.0;
      _totalReviews = 0;
      return;
    }
    double sum = 0;
    for (var review in _characterReviews) {
      sum += review.rating;
    }
    _averageRating = sum / _characterReviews.length;
    _totalReviews = _characterReviews.length;
  }

  Future<void> _checkBookmarkStatus() async {
    if (_currentUserId != null) {
      final isBookmarked =
          HiveService().isBookmarked(_currentUserId!, widget.characterId);
      setState(() {
        _isBookmarked = isBookmarked;
        _bookmarkLoading = false;
      });
    } else {
      setState(() {
        _isBookmarked = false;
        _bookmarkLoading = false;
      });
    }
  }

  Future<void> _toggleBookmark() async {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to bookmark characters')),
      );
      return;
    }

    setState(() {
      _bookmarkLoading = true;
    });
    final hiveService = HiveService();
    if (_isBookmarked) {
      final bookmarks = hiveService.bookmarkBox.values
          .where((b) =>
              b.userId == _currentUserId && b.characterId == widget.characterId)
          .toList();
      for (var b in bookmarks) {
        await b.delete();
      }
    } else {
      final newBookmark = BookmarkModel(
        userId: _currentUserId!,
        characterId: widget.characterId,
        timestamp: DateTime.now(),
      );
      await hiveService.addBookmark(newBookmark);
    }
    await _checkBookmarkStatus();
  }

  Future<void> _submitReview() async {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to submit a review')),
      );
      return;
    }

    final comment = _commentController.text.trim();
    if (comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a comment')),
      );
      return;
    }

    if (_editingReview != null) {
      _editingReview!.rating = _rating;
      _editingReview!.comment = comment;
      _editingReview!.timestamp = DateTime.now();
      await HiveService().updateReview(_editingReview!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review updated')),
      );
      _editingReview = null;
    } else {
      final newReview = ReviewModel(
        userId: _currentUserId!,
        characterId: widget.characterId,
        rating: _rating,
        comment: comment,
        timestamp: DateTime.now(),
      );
      await HiveService().addReview(newReview);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted')),
      );
    }

    await _loadReviews();
    _commentController.clear();
    setState(() {
      _rating = 3.0;
    });
  }

  Future<void> _editReview(ReviewModel review) async {
    setState(() {
      _editingReview = review;
      _rating = review.rating;
      _commentController.text = review.comment;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Scrollable.ensureVisible(
        _reviewTextFieldKey.currentContext!,
        alignment: 0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _deleteReview(ReviewModel review) async {
    await HiveService().deleteReview(review);
    await _loadReviews();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Review deleted')),
    );
  }

  Widget _buildDetailList(String title, List<dynamic>? items) {
    if (items != null && items.isNotEmpty) {
      return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$title:',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: 6.0,
                runSpacing: 6.0,
                children: items
                    .map<Widget>((item) => Chip(label: Text(item.toString())))
                    .toList(),
              ),
            ],
          ));
    }
    return const SizedBox.shrink();
  }

  Widget _buildStarRating(
      {required double rating,
      int maxStars = 5,
      double iconSize = 24.0,
      Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxStars, (index) {
        return Icon(
          index < rating.floor() ? Icons.star : Icons.star_border,
          color: color ?? Colors.amber,
          size: iconSize,
        );
      }),
    );
  }

  Widget _buildStarInput(
      {required double currentRating,
      required ValueChanged<double> onChanged,
      int maxStars = 5,
      double iconSize = 36.0}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxStars, (index) {
        return IconButton(
          icon: Icon(
            index < currentRating ? Icons.star : Icons.star_border,
            color: Colors.amber,
          ),
          iconSize: iconSize,
          onPressed: () => onChanged((index + 1).toDouble()),
        );
      }),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _characterFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        } else if (snapshot.hasError) {
          print('Error loading character detail: ${snapshot.error}');
          return Scaffold(
              body: Center(
                  child: Text(
            'Error: ${snapshot.error}\nTap to retry',
            textAlign: TextAlign.center,
          )));
        } else if (!snapshot.hasData || snapshot.data!['data'] == null) {
          return const Scaffold(
              body: Center(child: Text('No detail found or malformed data')));
        }

        final characterData = snapshot.data!['data'] as Map<String, dynamic>;

        print('Character data received: $characterData');

        return Scaffold(
          appBar: AppBar(
            title: Text(characterData['name'] ?? 'Detail'),
            actions: [
              _bookmarkLoading
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          )),
                    )
                  : IconButton(
                      icon: Icon(_isBookmarked
                          ? Icons.bookmark
                          : Icons.bookmark_border),
                      onPressed: _toggleBookmark,
                    ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (characterData['imageUrl'] != null &&
                    characterData['imageUrl'].isNotEmpty)
                  Center(
                    child: Image.network(
                      characterData['imageUrl'],
                      height: 300,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        print('Error loading image: $error');
                        return const Icon(Icons.broken_image, size: 100);
                      },
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  characterData['name'] ?? 'No Name',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (_totalReviews > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        _buildStarRating(rating: _averageRating),
                        const SizedBox(width: 8),
                        Text(
                          '${_averageRating.toStringAsFixed(1)} out of 5 (${_totalReviews} reviews)',
                          style:
                              const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                _buildDetailList(
                    'Films', characterData['films'] as List<dynamic>?),
                _buildDetailList('Short Films',
                    characterData['shortFilms'] as List<dynamic>?),
                _buildDetailList(
                    'TV Shows', characterData['tvShows'] as List<dynamic>?),
                _buildDetailList('Video Games',
                    characterData['videoGames'] as List<dynamic>?),
                _buildDetailList('Park Attractions',
                    characterData['parkAttractions'] as List<dynamic>?),
                _buildDetailList(
                    'Allies', characterData['allies'] as List<dynamic>?),
                _buildDetailList(
                    'Enemies', characterData['enemies'] as List<dynamic>?),
                const Divider(height: 32),
                const Text(
                  'Add Your Review',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Center(
                  child: _buildStarInput(
                    currentRating: _rating,
                    onChanged: (newRating) {
                      setState(() {
                        _rating = newRating;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  key: _reviewTextFieldKey,
                  controller: _commentController,
                  decoration: InputDecoration(
                    labelText:
                        _editingReview != null ? 'Edit Comment' : 'Comment',
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _submitReview,
                  child: Text(_editingReview != null
                      ? 'Update Review'
                      : 'Submit Review'),
                ),
                if (_editingReview != null)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _editingReview = null;
                        _commentController.clear();
                        _rating = 3.0;
                      });
                    },
                    child: const Text('Cancel Edit'),
                  ),
                const Divider(height: 32),
                const Text(
                  'Reviews',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _characterReviews.isEmpty
                    ? const Text('No reviews yet.')
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _characterReviews.length,
                        itemBuilder: (context, index) {
                          final review = _characterReviews[index];
                          bool isMyReview = (_currentUserId != null &&
                              review.userId == _currentUserId);
                          // Ambil username berdasarkan userId dari map _usernames
                          String reviewerUsername =
                              _usernames[review.userId] ?? 'Unknown User';

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildStarRating(
                                          rating: review.rating,
                                          iconSize: 18.0),
                                      if (isMyReview)
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit,
                                                  size: 20),
                                              onPressed: () =>
                                                  _editReview(review),
                                              tooltip: 'Edit Review',
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete,
                                                  size: 20),
                                              onPressed: () =>
                                                  _deleteReview(review),
                                              tooltip: 'Delete Review',
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                  Text(review.comment),
                                  Text(
                                    'By $reviewerUsername at ${review.timestamp.toLocal().toString().split('.')[0]}', // Tampilkan username
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        );
      },
    );
  }
}
