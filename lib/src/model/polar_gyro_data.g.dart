// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: unnecessary_cast, require_trailing_commas

part of 'polar_gyro_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PolarGyroData _$PolarGyroDataFromJson(Map<String, dynamic> json) =>
    PolarGyroData(
      (json['timeStamp'] as num).toInt(),
      (json['samples'] as List<dynamic>)
          .map((e) => GyroSample.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PolarGyroDataToJson(PolarGyroData instance) =>
    <String, dynamic>{
      'timeStamp': instance.timeStamp,
      'samples': instance.samples,
    };

GyroSample _$GyroSampleFromJson(Map<String, dynamic> json) => GyroSample(
      (json['timeStamp'] as num).toInt(),
      (json['x'] as num).toDouble(),
      (json['y'] as num).toDouble(),
      (json['z'] as num).toDouble(),
    );

Map<String, dynamic> _$GyroSampleToJson(GyroSample instance) =>
    <String, dynamic>{
      'timeStamp': instance.timeStamp,
      'x': instance.x,
      'y': instance.y,
      'z': instance.z,
    };
