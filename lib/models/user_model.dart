import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 2)
class UserModel extends HiveObject {
  @HiveField(0)
  int id; // bisa manual atau generate

  @HiveField(1)
  String username;

  @HiveField(2)
  String password;
  @HiveField(3)
  DateTime createdAt;

  UserModel({
    required this.id,
    required this.username,
    required this.password,
    required this.createdAt,
  });
}
