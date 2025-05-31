import 'package:flutter/material.dart';
import '../services/disney_service.dart';
import '../services/hive_service.dart';
import '../models/review_model.dart';
import '../models/bookmark_model.dart';

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

  final int _userId = 1; // Simulasi userId

  bool _isBookmarked = false;
  bool _bookmarkLoading = true;

  @override
  void initState() {
    super.initState();
    _characterFuture = DisneyService.fetchCharacterDetail(widget.characterId);
    _checkBookmarkStatus();
  }

  Future<void> _checkBookmarkStatus() async {
    final isBookmarked = HiveService().isBookmarked(_userId, widget.characterId);
    setState(() {
      _isBookmarked = isBookmarked;
      _bookmarkLoading = false;
    });
  }

  Future<void> _toggleBookmark() async {
    setState(() {
      _bookmarkLoading = true;
    });
    final hiveService = HiveService();
    if (_isBookmarked) {
      final bookmarks = hiveService.bookmarkBox.values
          .where((b) => b.userId == _userId && b.characterId == widget.characterId)
          .toList();
      for (var b in bookmarks) {
        await b.delete();
      }
    } else {
      final newBookmark = BookmarkModel(
        userId: _userId,
        characterId: widget.characterId,
        timestamp: DateTime.now(),
      );
      await hiveService.addBookmark(newBookmark);
    }
    await _checkBookmarkStatus();
  }

  Future<void> _submitReview() async {
    final comment = _commentController.text.trim();
    if (comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a comment')),
      );
      return;
    }

    final newReview = ReviewModel(
      userId: _userId,
      characterId: widget.characterId,
      rating: _rating,
      comment: comment,
      timestamp: DateTime.now(),
    );

    await HiveService().addReview(newReview);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Review submitted')),
    );

    _commentController.clear();
    setState(() {
      _rating = 3.0;
    });
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
          return Scaffold(
              body: Center(child: Text('Error: ${snapshot.error}')));
        } else if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: Text('No detail found')));
        }

        final character = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: Text(character['name'] ?? 'Detail'),
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
                      icon: Icon(
                          _isBookmarked ? Icons.bookmark : Icons.bookmark_border),
                      onPressed: _toggleBookmark,
                    ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (character['imageUrl'] != null)
                  Center(
                    child: Image.network(
                      character['imageUrl'],
                      height: 300,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  character['name'] ?? 'No Name',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (character['films'] != null &&
                    (character['films'] as List).isNotEmpty)
                  Text(
                    'Films: ${(character['films'] as List).join(', ')}',
                    style: const TextStyle(fontSize: 16),
                  ),
                if (character['tvShows'] != null &&
                    (character['tvShows'] as List).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'TV Shows: ${(character['tvShows'] as List).join(', ')}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                if (character['videoGames'] != null &&
                    (character['videoGames'] as List).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Video Games: ${(character['videoGames'] as List).join(', ')}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                const Divider(height: 32),
                const Text(
                  'Add Your Review',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Slider(
                  value: _rating,
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: _rating.toString(),
                  onChanged: (value) {
                    setState(() {
                      _rating = value;
                    });
                  },
                ),
                TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    labelText: 'Comment',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _submitReview,
                  child: const Text('Submit Review'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
