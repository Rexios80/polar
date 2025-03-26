// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'polar_offline_record_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PolarOfflineRecordingEntry _$PolarOfflineRecordingEntryFromJson(
  Map<String, dynamic> json,
) {
  return PolarOfflineRecordingEntry(
    path: json['path'] as String,
    size: json['size'] as int,
    date: const UnixTimeConverter().fromJson((json['date'] as num).toInt()),
    type: const PolarDataTypeConverter().fromJson(json['type']),
  );
}

Map<String, dynamic> _$PolarOfflineRecordingEntryToJson(
  PolarOfflineRecordingEntry instance,
) =>
    <String, dynamic>{
      'path': instance.path,
      'size': instance.size,
      'date': const UnixTimeConverter().toJson(instance.date),
      'type': const PolarDataTypeConverter().toJson(instance.type),
    };
