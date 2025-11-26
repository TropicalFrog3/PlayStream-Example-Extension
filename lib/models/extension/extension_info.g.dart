// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'extension_info.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExtensionInfoAdapter extends TypeAdapter<ExtensionInfo> {
  @override
  final int typeId = 10;

  @override
  ExtensionInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExtensionInfo(
      id: fields[0] as String,
      name: fields[1] as String,
      version: fields[2] as String,
      description: fields[3] as String,
      downloadUrl: fields[4] as String,
      iconUrl: fields[5] as String,
      size: fields[6] as int,
      updatedAt: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ExtensionInfo obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.version)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.downloadUrl)
      ..writeByte(5)
      ..write(obj.iconUrl)
      ..writeByte(6)
      ..write(obj.size)
      ..writeByte(7)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExtensionInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
