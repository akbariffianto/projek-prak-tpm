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
  String? favoriteCharacterId;

  @HiveField(6)
  String? favoriteCharacterName;

  @HiveField(7)
  String? description;

  UserModel({
    required this.id,
    required this.username,
    required this.password,
    required this.createdAt,
    this.profilePhotoPath,
    this.favoriteCharacterId,
    this.favoriteCharacterName,
    this.description,
  });
}
