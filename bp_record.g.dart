// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bp_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BPRecordAdapter extends TypeAdapter<BPRecord> {
  @override
  final int typeId = 1;

  @override
  BPRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BPRecord(
      timestamp: fields[0] as DateTime,
      systolic: fields[1] as int,
      diastolic: fields[2] as int,
      pulse: fields[3] as int,
      condition: fields[4] as String,
      signalQuality: fields[5] as SignalQuality,
    );
  }

  @override
  void write(BinaryWriter writer, BPRecord obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.timestamp)
      ..writeByte(1)
      ..write(obj.systolic)
      ..writeByte(2)
      ..write(obj.diastolic)
      ..writeByte(3)
      ..write(obj.pulse)
      ..writeByte(4)
      ..write(obj.condition)
      ..writeByte(5)
      ..write(obj.signalQuality);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BPRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
