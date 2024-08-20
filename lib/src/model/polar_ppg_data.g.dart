// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: unnecessary_cast, require_trailing_commas

part of 'polar_ppg_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PolarPpgData _$PolarPpgDataFromJson(Map<String, dynamic> json) => PolarPpgData(
      json['type'] as String,
      (json['samples'] as List<dynamic>)
          .map((e) => PpgSample.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PolarPpgDataToJson(PolarPpgData instance) =>
    <String, dynamic>{
      'type': instance.type,
      'samples': instance.samples,
    };

PpgSample _$PpgSampleFromJson(Map<String, dynamic> json) => PpgSample(
      (json['timeStamp'] as num).toInt(),
      (json['channelSamples'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
    );

Map<String, dynamic> _$PpgSampleToJson(PpgSample instance) => <String, dynamic>{
      'timeStamp': instance.timeStamp,
      'channelSamples': instance.channelSamples,
    };
