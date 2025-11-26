// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 2;

  @override
  UserProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProfile(
      id: fields[0] as String,
      name: fields[1] as String,
      avatarColor: fields[2] as String,
      avatarIcon: fields[3] as String?,
      createdAt: fields[4] as DateTime,
      lastUsed: fields[5] as DateTime,
      traktAccessToken: fields[6] as String?,
      traktRefreshToken: fields[7] as String?,
      traktTokenExpiry: fields[8] as DateTime?,
      traktUsername: fields[9] as String?,
      lastTraktSync: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.avatarColor)
      ..writeByte(3)
      ..write(obj.avatarIcon)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.lastUsed)
      ..writeByte(6)
      ..write(obj.traktAccessToken)
      ..writeByte(7)
      ..write(obj.traktRefreshToken)
      ..writeByte(8)
      ..write(obj.traktTokenExpiry)
      ..writeByte(9)
      ..write(obj.traktUsername)
      ..writeByte(10)
      ..write(obj.lastTraktSync);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
