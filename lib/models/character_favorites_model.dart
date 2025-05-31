import 'package:hive/hive.dart';

part 'character_favorites_model.g.dart';

@HiveType(typeId: 3)
class CharacterFavoritesModel extends HiveObject {
  @HiveField(0)
  String characterId;

  @HiveField(1)
  String characterName;

  @HiveField(2)
  int favoriteCount;

  CharacterFavoritesModel({
    required this.characterId,
    required this.characterName,
    required this.favoriteCount,
  });
}