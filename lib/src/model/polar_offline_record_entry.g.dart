// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: document_ignores, unnecessary_cast, require_trailing_commas

part of 'polar_offline_record_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PolarOfflineRecordingEntry _$PolarOfflineRecordingEntryFromJson(
        Map<String, dynamic> json) =>
    PolarOfflineRecordingEntry(
      path: json['path'] as String,
      size: (json['size'] as num).toInt(),
      date: const UnixTimeConverter().fromJson((json['date'] as num).toInt()),
      type: const PolarDataTypeConverter().fromJson(json['type']),
    );

Map<String, dynamic> _$PolarOfflineRecordingEntryToJson(
        PolarOfflineRecordingEntry instance) =>
    <String, dynamic>{
      'path': instance.path,
      'size': instance.size,
      'date': const UnixTimeConverter().toJson(instance.date),
      'type': const PolarDataTypeConverter().toJson(instance.type),
    };
