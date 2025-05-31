import 'package:hive/hive.dart';

part 'bookmark_model.g.dart';

@HiveType(typeId: 1)
class BookmarkModel extends HiveObject {
  @HiveField(0)
  int userId;

  @HiveField(1)
  int characterId;

  @HiveField(2)
  DateTime timestamp;

  BookmarkModel({
    required this.userId,
    required this.characterId,
    required this.timestamp,
  });
}
