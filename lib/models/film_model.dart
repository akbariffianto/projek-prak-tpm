class Film {
  final int id; // dari API
  final String title;
  final String imageUrl;
  final List<String> categories;

  Film({required this.id, required this.title, required this.imageUrl, required this.categories});

  factory Film.fromJson(Map<String, dynamic> json) {
    return Film(
      id: json['_id'] ?? 0,
      title: json['title'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      categories: List<String>.from(json['genres'] ?? []),
    );
  }
}
