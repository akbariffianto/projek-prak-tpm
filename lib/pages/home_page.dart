import 'package:flutter/material.dart';
import '../services/disney_service.dart';
import '../services/hive_service.dart';
import 'detail_page.dart';
import 'bookmark_page.dart';
import 'search_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<dynamic>> _charactersFuture;
  String _loggedInUsername = 'Guest';
  int _currentIndex = 0;
  final _hiveService = HiveService();

  @override
  void initState() {
    super.initState();
    _charactersFuture = DisneyService.fetchCharacters();
    _loadLoggedInUsernameAndProfile();
  }

  Future<void> _loadLoggedInUsernameAndProfile() async {
    try {
      final userId = await _hiveService.getUserSession();
      if (userId != null) {
        final user = _hiveService.userBox.values.firstWhere(
          (u) => u.id == userId,
          orElse: () => throw Exception('User not found'),
        );
        if (mounted) {
          setState(() {
            _loggedInUsername = user.username;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading username or profile: $e');
      if (mounted) {
        setState(() {
          _loggedInUsername = 'Guest';
        });
      }
    }
  }

  Widget _buildTopCharactersCard(Map<String, dynamic> character, int index) {
    final bookmarkCount = _hiveService.getBookmarkCounts()[character['_id']] ?? 0;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: CachedNetworkImageProvider(character['imageUrl'] ?? ''),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Top ${index + 1}: ${character['name']}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$bookmarkCount Bookmarks',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterCard(Map<String, dynamic> character) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailPage(characterId: character['_id']),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: CachedNetworkImage(
                imageUrl: character['imageUrl'] ?? '',
                fit: BoxFit.cover,
                placeholder: (context, url) => Center(
                  child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.primary,),
                ),
                errorWidget: (context, url, error) => Icon(
                  Icons.person,
                  size: 50,
                  color: Colors.grey[400],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    character['name'] ?? 'No Name',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridView(List<dynamic> characters) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: characters.length,
      itemBuilder: (_, index) => _buildCharacterCard(characters[index]),
    );
  }

  Widget _buildHomeContent() {
    return FutureBuilder<List<dynamic>>(
      future: _charactersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No characters found'));
        }

        final characters = snapshot.data!;
        final bookmarkCounts = _hiveService.getBookmarkCounts();
        
        // Sort characters by bookmark count
        final sortedCharacters = List<Map<String, dynamic>>.from(characters)
          ..sort((a, b) {
            final aCount = bookmarkCounts[a['_id']] ?? 0;
            final bCount = bookmarkCounts[b['_id']] ?? 0;
            return bCount.compareTo(aCount); // Sort in descending order
          });

        final topCharacters = sortedCharacters.take(3).toList();

        return Column(
          children: [
            SizedBox(
              height: 200,
              child: PageView.builder(
                itemCount: topCharacters.length,
                itemBuilder: (context, index) =>
                    _buildTopCharactersCard(topCharacters[index], index),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildGridView(characters)),
          ],
        );
      },
    );
  }

  Widget _buildSearchContent() {
    return const SearchPage();
  }

  Widget _buildProfileContent() {
    return const ProfilePage();
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return _buildSearchContent();
      case 2:
        return _buildProfileContent();
      default:
        return _buildHomeContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentIndex == 0
              ? 'Welcome back,\n$_loggedInUsername'
              : _currentIndex == 1
                  ? 'Search Characters'
                  : 'Profile',
        ),
        actions: [
          if (_currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.bookmark),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BookmarkPage()),
              ),
            ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 2) {
            _loadLoggedInUsernameAndProfile();
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}