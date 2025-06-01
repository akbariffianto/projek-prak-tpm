// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character_favorites_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CharacterFavoritesModelAdapter
    extends TypeAdapter<CharacterFavoritesModel> {
  @override
  final int typeId = 3;

  @override
  CharacterFavoritesModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CharacterFavoritesModel(
      characterId: fields[0] as int,
      characterName: fields[1] as String,
      favoriteCount: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, CharacterFavoritesModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.characterId)
      ..writeByte(1)
      ..write(obj.characterName)
      ..writeByte(2)
      ..write(obj.favoriteCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CharacterFavoritesModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
