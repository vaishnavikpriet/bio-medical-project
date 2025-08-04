// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signal_quality.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SignalQualityAdapter extends TypeAdapter<SignalQuality> {
  @override
  final int typeId = 2;

  @override
  SignalQuality read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SignalQuality.poor;
      case 1:
        return SignalQuality.fair;
      case 2:
        return SignalQuality.good;
      case 3:
        return SignalQuality.excellent;
      default:
        return SignalQuality.poor;
    }
  }

  @override
  void write(BinaryWriter writer, SignalQuality obj) {
    switch (obj) {
      case SignalQuality.poor:
        writer.writeByte(0);
        break;
      case SignalQuality.fair:
        writer.writeByte(1);
        break;
      case SignalQuality.good:
        writer.writeByte(2);
        break;
      case SignalQuality.excellent:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SignalQualityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
