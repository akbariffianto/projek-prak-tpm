import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/bookmark_model.dart';
import '../services/hive_service.dart';
import 'detail_page.dart';

class BookmarkPage extends StatefulWidget {
  const BookmarkPage({super.key});

  @override
  State<BookmarkPage> createState() => _BookmarkPageState();
}

class _BookmarkPageState extends State<BookmarkPage> {
  final int userId = 1; // Simulasi user
  late Box<BookmarkModel> bookmarkBox;

  @override
  void initState() {
    super.initState();
    bookmarkBox = HiveService().bookmarkBox;
  }

  @override
  Widget build(BuildContext context) {
    final bookmarks = bookmarkBox.values.where((b) => b.userId == userId).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Bookmarks')),
      body: bookmarks.isEmpty
          ? const Center(child: Text('No bookmarks found.'))
          : ListView.builder(
              itemCount: bookmarks.length,
              itemBuilder: (context, index) {
                final BookmarkModel bookmark = bookmarks[index];
                return ListTile(
                  title: Text('Character ID: ${bookmark.characterId}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      await bookmark.delete();
                      setState(() {});
                    },
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailPage(characterId: bookmark.characterId),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
