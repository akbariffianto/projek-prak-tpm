import 'package:flutter/material.dart';
import '../services/disney_service.dart';
import 'detail_page.dart';
import 'bookmark_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<dynamic>> _charactersFuture;

  @override
  void initState() {
    super.initState();
    _charactersFuture = DisneyService.fetchCharacters(); // Panggil service Disney
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Disney Characters'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BookmarkPage()),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _charactersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No characters found.'));
          }

          final characters = snapshot.data!;

          return ListView.builder(
            itemCount: characters.length,
            itemBuilder: (context, index) {
              final character = characters[index];
              return ListTile(
                leading: character['imageUrl'] != null
                    ? Image.network(
                        character['imageUrl'],
                        width: 50,
                        fit: BoxFit.cover,
                      )
                    : const SizedBox(width: 50),
                title: Text(character['name'] ?? 'No name'),
                subtitle: Text(
                  (character['films'] != null && (character['films'] as List).isNotEmpty)
                      ? 'Film: ${(character['films'] as List).join(', ')}'
                      : 'No films',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetailPage(characterId: character['_id']),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
