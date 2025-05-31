import 'package:flutter/material.dart';
import '../services/disney_service.dart';
import '../services/hive_service.dart';
import 'detail_page.dart';
import 'bookmark_page.dart';
import 'login_page.dart';
import 'search_page.dart';

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
    _loadLoggedInUsername();
  }

  Future<void> _loadLoggedInUsername() async {
    try {
      final userId = await _hiveService.getUserSession();
      if (userId != null) {
        final user = _hiveService.userBox.values.firstWhere(
          (u) => u.id == userId,
          orElse: () => throw Exception('User not found'),
        );
        if (mounted) {
          setState(() => _loggedInUsername = user.username);
        }
      }
    } catch (e) {
      debugPrint('Error loading username: $e');
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _hiveService.logout();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  Widget _buildTopCharactersCard(Map<String, dynamic> character, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(character['imageUrl'] ?? ''),
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
                  _buildFavoriteCount(character['_id'].toString()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteCount(String characterId) {
    return FutureBuilder<int>(
      future: _hiveService.getCharacterFavoriteCount(characterId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text(
            'Loading...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          );
        }
        return Text(
          '${snapshot.data ?? 0} favorites',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        );
      },
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
              child: Image.network(
                character['imageUrl'] ?? '',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
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
                  _buildFavoriteCount(character['_id'].toString()),
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
        final topCharacters = characters.take(3).toList();

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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey,
            child: Icon(Icons.person, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            _loggedInUsername,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          ListTile(
            leading: const Icon(Icons.bookmark),
            title: const Text('My Bookmarks'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BookmarkPage()),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
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
        onTap: (index) => setState(() => _currentIndex = index),
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