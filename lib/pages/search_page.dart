import 'package:flutter/material.dart';
import '../services/disney_service.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  List<dynamic>? _searchResults;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search characters...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onSubmitted: (value) async {
              setState(() => _isLoading = true);
              try {
                final results = await DisneyService.searchCharacters(value);
                setState(() => _searchResults = results);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              } finally {
                setState(() => _isLoading = false);
              }
            },
          ),
        ),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_searchResults != null)
          Expanded(
            child: ListView.builder(
              itemCount: _searchResults!.length,
              itemBuilder: (context, index) {
                final character = _searchResults![index];
                return ListTile(
                  leading: Image.network(
                    character['imageUrl'] ?? '',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.person, size: 50),
                  ),
                  title: Text(character['name'] ?? 'No Name'),
                  onTap: () {
                    // Navigate to detail page
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}