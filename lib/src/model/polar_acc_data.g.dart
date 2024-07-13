// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: unnecessary_cast, require_trailing_commas

part of 'polar_acc_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PolarAccData _$PolarAccDataFromJson(Map<String, dynamic> json) => PolarAccData(
      (json['timeStamp'] as num).toInt(),
      (json['samples'] as List<dynamic>)
          .map((e) => AccSample.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PolarAccDataToJson(PolarAccData instance) =>
    <String, dynamic>{
      'timeStamp': instance.timeStamp,
      'samples': instance.samples,
    };

AccSample _$AccSampleFromJson(Map<String, dynamic> json) => AccSample(
      (json['timeStamp'] as num).toInt(),
      (json['x'] as num).toInt(),
      (json['y'] as num).toInt(),
      (json['z'] as num).toInt(),
    );

Map<String, dynamic> _$AccSampleToJson(AccSample instance) => <String, dynamic>{
      'timeStamp': instance.timeStamp,
      'x': instance.x,
      'y': instance.y,
      'z': instance.z,
    };
