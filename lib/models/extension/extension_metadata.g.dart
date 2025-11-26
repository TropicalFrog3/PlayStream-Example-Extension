// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'extension_metadata.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExtensionMetadataAdapter extends TypeAdapter<ExtensionMetadata> {
  @override
  final int typeId = 11;

  @override
  ExtensionMetadata read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExtensionMetadata(
      id: fields[0] as String,
      name: fields[1] as String,
      version: fields[2] as String,
      apkPath: fields[3] as String,
      isEnabled: fields[4] as bool,
      installedAt: fields[5] as DateTime,
      settings: (fields[6] as Map).cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, ExtensionMetadata obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.version)
      ..writeByte(3)
      ..write(obj.apkPath)
      ..writeByte(4)
      ..write(obj.isEnabled)
      ..writeByte(5)
      ..write(obj.installedAt)
      ..writeByte(6)
      ..write(obj.settings);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExtensionMetadataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
