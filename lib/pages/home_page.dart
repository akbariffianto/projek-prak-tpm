// Path: lib/pages/home_page.dart
import 'package:flutter/material.dart';
import '../services/disney_service.dart';
import '../services/hive_service.dart';
import '../models/user_model.dart'; // Import UserModel
import 'detail_page.dart';
import 'bookmark_page.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<dynamic>> _charactersFuture;
  String _loggedInUsername = 'Guest'; // Default username

  @override
  void initState() {
    super.initState();
    _charactersFuture = DisneyService.fetchCharacters();
    _loadLoggedInUsername(); // Panggil fungsi untuk memuat username
  }

  // Fungsi untuk memuat username user yang sedang login
  Future<void> _loadLoggedInUsername() async {
    final hiveService = HiveService();
    final userId = await hiveService.getUserSession();
    if (userId != null) {
      // Perbaikan di sini: Cari user berdasarkan id di antara semua nilai userBox
      final user = hiveService.userBox.values.firstWhere(
        (u) => u.id == userId,
        orElse: () => throw Exception(
            'User not found in Hive'), // Tambahkan fallback atau penanganan error
      );

      setState(() {
        _loggedInUsername = user.username;
      });
    }
  }

  // Fungsi untuk melakukan logout
  Future<void> _logout() async {
    await HiveService().clearUserSession();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hi, $_loggedInUsername!'), // Judul sudah Hi, Username!
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BookmarkPage()),
              );
            },
            tooltip: 'Bookmarks',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _charactersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline,
                        size: 50, color: Theme.of(context).colorScheme.error),
                    const SizedBox(height: 10),
                    Text(
                      'Failed to load characters. Error: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _charactersFuture = DisneyService
                              .fetchCharacters(); // Coba muat ulang
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sentiment_dissatisfied,
                      size: 50, color: Colors.grey.shade500),
                  const SizedBox(height: 10),
                  const Text('No characters found.'),
                ],
              ),
            );
          }

          final characters = snapshot.data!;

          return ListView.builder(
            padding:
                const EdgeInsets.symmetric(vertical: 8), // Padding untuk list
            itemCount: characters.length,
            itemBuilder: (context, index) {
              final character = characters[index];
              return Card(
                clipBehavior: Clip.antiAlias, // Penting untuk gambar melengkung
                child: InkWell(
                  // Efek riak saat ditekan
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            DetailPage(characterId: character['_id']),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        ClipRRect(
                          // Gambar lingkaran
                          borderRadius: BorderRadius.circular(8.0),
                          child: character['imageUrl'] != null &&
                                  character['imageUrl'].isNotEmpty
                              ? Image.network(
                                  character['imageUrl'],
                                  width: 70, // Ukuran gambar lebih besar
                                  height: 70,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    width: 70,
                                    height: 70,
                                    color: Colors.grey[300],
                                    child: Icon(Icons.person,
                                        size: 40, color: Colors.grey[600]),
                                  ),
                                )
                              : Container(
                                  width: 70,
                                  height: 70,
                                  color: Colors.grey[300],
                                  child: Icon(Icons.person,
                                      size: 40, color: Colors.grey[600]),
                                ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                character['name'] ?? 'No Name',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                (character['films'] != null &&
                                        (character['films'] as List).isNotEmpty)
                                    ? 'Film: ${(character['films'] as List).join(', ')}'
                                    : 'No films',
                                style: TextStyle(
                                    color: Colors.grey.shade700, fontSize: 14),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios,
                            size: 16, color: Colors.grey), // Indikator navigasi
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
