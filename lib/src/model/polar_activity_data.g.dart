// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: document_ignores, unnecessary_cast, require_trailing_commas, rexios_lints/not_null_assertion

part of 'polar_activity_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Polar247HrSamples _$Polar247HrSamplesFromJson(Map<String, dynamic> json) =>
    Polar247HrSamples(
      startTime: json['startTime'] as String,
      hrSamples: (json['hrSamples'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      triggerType: json['triggerType'] as String,
    );

Map<String, dynamic> _$Polar247HrSamplesToJson(Polar247HrSamples instance) =>
    <String, dynamic>{
      'startTime': instance.startTime,
      'hrSamples': instance.hrSamples,
      'triggerType': instance.triggerType,
    };

Polar247HrSamplesData _$Polar247HrSamplesDataFromJson(
  Map<String, dynamic> json,
) => Polar247HrSamplesData(
  date: const Iso8601DateConverter().fromJson(json['date'] as String),
  samples: (json['samples'] as List<dynamic>)
      .map((e) => Polar247HrSamples.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$Polar247HrSamplesDataToJson(
  Polar247HrSamplesData instance,
) => <String, dynamic>{
  'date': const Iso8601DateConverter().toJson(instance.date),
  'samples': instance.samples,
};
