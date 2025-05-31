import 'package:hive/hive.dart';

part 'review_model.g.dart';

@HiveType(typeId: 0)
class ReviewModel extends HiveObject {
  @HiveField(0)
  int userId;

  @HiveField(1)
  int characterId;

  @HiveField(2)
  double rating;

  @HiveField(3)
  String comment;

  @HiveField(4)
  DateTime timestamp;

  ReviewModel({
    required this.userId,
    required this.characterId,
    required this.rating,
    required this.comment,
    required this.timestamp,
  });
}
