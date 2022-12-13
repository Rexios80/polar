// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: unnecessary_cast, require_trailing_commas

part of 'polar_recording.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PolarExerciseEntry _$PolarExerciseEntryFromJson(Map<String, dynamic> json) =>
    PolarExerciseEntry(
      path: json['path'] as String,
      date: const UnixTimeConverter().fromJson(json['date'] as int),
      entryId: PolarExerciseEntry._readEntryId(json, 'entryId') as String,
    );

PolarExerciseData _$PolarExerciseDataFromJson(Map<String, dynamic> json) =>
    PolarExerciseData(
      interval: PolarExerciseData._readInterval(json, 'interval') as int,
      samples:
          (PolarExerciseData._readSamples(json, 'samples') as List<dynamic>)
              .map((e) => e as int)
              .toList(),
    );
