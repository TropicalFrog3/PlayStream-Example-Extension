// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'extension_preferences.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExtensionPreferencesAdapter extends TypeAdapter<ExtensionPreferences> {
  @override
  final int typeId = 12;

  @override
  ExtensionPreferences read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExtensionPreferences(
      extensionId: fields[0] as String,
      serverPreferences: (fields[1] as Map).cast<String, String>(),
      lastUpdateCheck: fields[2] as DateTime?,
      consecutiveFailures: fields[3] as int,
      lastFailureTime: fields[4] as DateTime?,
      isProblematic: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ExtensionPreferences obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.extensionId)
      ..writeByte(1)
      ..write(obj.serverPreferences)
      ..writeByte(2)
      ..write(obj.lastUpdateCheck)
      ..writeByte(3)
      ..write(obj.consecutiveFailures)
      ..writeByte(4)
      ..write(obj.lastFailureTime)
      ..writeByte(5)
      ..write(obj.isProblematic);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExtensionPreferencesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
