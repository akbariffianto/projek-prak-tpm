import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 2)
class UserModel extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  String username;

  @HiveField(2)
  String password;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  String? profilePhotoPath;

  @HiveField(5)
  int? favoriteCharacterId; // Tetap int?, tapi kini opsional

  @HiveField(6)
  String? favoriteCharacterName; // Tetap String?, tapi kini opsional

  @HiveField(7)
  String? description;

  UserModel({
    required this.id,
    required this.username,
    required this.password,
    required this.createdAt,
    this.profilePhotoPath,
    this.favoriteCharacterId, // Pastikan ini opsional di konstruktor
    this.favoriteCharacterName, // Pastikan ini opsional di konstruktor
    this.description,
  });
}