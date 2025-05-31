// Path: lib/pages/bookmark_page.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/bookmark_model.dart';
import '../services/hive_service.dart';
import '../services/disney_service.dart'; // Import DisneyService
import 'detail_page.dart';

class BookmarkPage extends StatefulWidget {
  const BookmarkPage({super.key});

  @override
  State<BookmarkPage> createState() => _BookmarkPageState();
}

class _BookmarkPageState extends State<BookmarkPage> {
  int? _currentUserId;
  late Box<BookmarkModel> bookmarkBox;
  List<BookmarkModel> _bookmarks = [];
  // Tambahkan map untuk menyimpan detail karakter yang di-bookmark
  Map<int, Map<String, dynamic>> _bookmarkedCharacterDetails = {};
  bool _isLoadingDetails = true; // State untuk loading detail karakter

  @override
  void initState() {
    super.initState();
    bookmarkBox = HiveService().bookmarkBox;
    _loadUserAndBookmarks();
  }

  Future<void> _loadUserAndBookmarks() async {
    _currentUserId = await HiveService().getUserSession();
    if (_currentUserId != null) {
      await _fetchBookmarks(); // Pastikan bookmark ter-fetch sebelum detail
      await _fetchBookmarkedCharacterDetails();
    }
    setState(() {
      _isLoadingDetails = false; // Setelah semua dimuat, set loading ke false
    });
  }

  Future<void> _fetchBookmarks() async {
    if (_currentUserId != null) {
      _bookmarks =
          bookmarkBox.values.where((b) => b.userId == _currentUserId).toList();
      // Sortir bookmark berdasarkan timestamp terbaru
      _bookmarks.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }
  }

  Future<void> _fetchBookmarkedCharacterDetails() async {
    if (_bookmarks.isEmpty) {
      setState(() {
        _bookmarkedCharacterDetails = {}; // Reset jika tidak ada bookmark
      });
      return;
    }

    Map<int, Map<String, dynamic>> tempDetails = {};
    for (var bookmark in _bookmarks) {
      // Hanya fetch jika detail belum ada atau perlu di-refresh
      if (!tempDetails.containsKey(bookmark.characterId)) {
        try {
          final detail =
              await DisneyService.fetchCharacterDetail(bookmark.characterId);
          tempDetails[bookmark.characterId] =
              detail['data']; // Ambil data karakter dari respons
        } catch (e) {
          print(
              'Failed to fetch detail for character ID ${bookmark.characterId}: $e');
          // Fallback jika gagal fetch (misal: karakter tidak ditemukan)
          tempDetails[bookmark.characterId] = {
            'name': 'Unknown Character',
            'imageUrl': null,
          };
        }
      }
    }
    setState(() {
      _bookmarkedCharacterDetails = tempDetails;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Bookmarks')),
      body: _currentUserId == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline,
                        size: 50, color: Colors.grey.shade500),
                    const SizedBox(height: 10),
                    Text(
                      'Please login to view your bookmarks.',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(color: Colors.grey.shade700, fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          : _isLoadingDetails
              ? const Center(
                  child:
                      CircularProgressIndicator()) // Tampilkan loading saat fetch detail
              : _bookmarks.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bookmark_border,
                                size: 50, color: Colors.grey.shade500),
                            const SizedBox(height: 10),
                            Text(
                              'You haven\'t bookmarked any characters yet.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.grey.shade700, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _bookmarks.length,
                      itemBuilder: (context, index) {
                        final BookmarkModel bookmark = _bookmarks[index];
                        final characterDetail =
                            _bookmarkedCharacterDetails[bookmark.characterId];

                        // Fallback jika detail karakter belum dimuat atau tidak ditemukan
                        String characterName = characterDetail?['name'] ??
                            'Loading / Unknown Character';
                        String? imageUrl = characterDetail?['imageUrl'];

                        return Card(
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DetailPage(
                                      characterId: bookmark.characterId),
                                ),
                              ).then((_) {
                                // Refresh both bookmarks and details when returning from DetailPage
                                _loadUserAndBookmarks();
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  // Gambar Karakter
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: imageUrl != null &&
                                            imageUrl.isNotEmpty
                                        ? Image.network(
                                            imageUrl,
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Container(
                                              width: 60,
                                              height: 60,
                                              color: Colors.grey[300],
                                              child: Icon(Icons.person,
                                                  size: 30,
                                                  color: Colors.grey[600]),
                                            ),
                                          )
                                        : Container(
                                            width: 60,
                                            height: 60,
                                            color: Colors.grey[300],
                                            child: Icon(Icons.person,
                                                size: 30,
                                                color: Colors.grey[600]),
                                          ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          characterName, // Tampilkan Nama Karakter
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Bookmarked on: ${bookmark.timestamp.toLocal().toString().split('.')[0]}',
                                          style: TextStyle(
                                              color: Colors.grey.shade700,
                                              fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () async {
                                      await bookmark.delete();
                                      // Setelah dihapus, muat ulang semua data
                                      _loadUserAndBookmarks();
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text('Bookmark removed!')),
                                      );
                                    },
                                    tooltip: 'Remove Bookmark',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
