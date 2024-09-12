// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: document_ignores, unnecessary_cast, require_trailing_commas

part of 'polar_recording.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PolarExerciseEntry _$PolarExerciseEntryFromJson(Map<String, dynamic> json) =>
    PolarExerciseEntry(
      path: json['path'] as String,
      date: const UnixTimeConverter().fromJson((json['date'] as num).toInt()),
      entryId: _readEntryId(json, 'entryId') as String,
    );

Map<String, dynamic> _$PolarExerciseEntryToJson(PolarExerciseEntry instance) =>
    <String, dynamic>{
      'path': instance.path,
      'date': const UnixTimeConverter().toJson(instance.date),
    };

PolarExerciseData _$PolarExerciseDataFromJson(Map<String, dynamic> json) =>
    PolarExerciseData(
      interval: (_readInterval(json, 'interval') as num).toInt(),
      samples: (_readSamples(json, 'samples') as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
    );

Map<String, dynamic> _$PolarExerciseDataToJson(PolarExerciseData instance) =>
    <String, dynamic>{
      'interval': instance.interval,
      'samples': instance.samples,
    };
