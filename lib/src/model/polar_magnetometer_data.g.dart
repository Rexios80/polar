// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: unnecessary_cast, require_trailing_commas

part of 'polar_magnetometer_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PolarMagnetometerData _$PolarMagnetometerDataFromJson(
        Map<String, dynamic> json) =>
    PolarMagnetometerData(
      (json['timeStamp'] as num).toInt(),
      (json['samples'] as List<dynamic>)
          .map((e) => MagnetometerSample.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PolarMagnetometerDataToJson(
        PolarMagnetometerData instance) =>
    <String, dynamic>{
      'timeStamp': instance.timeStamp,
      'samples': instance.samples,
    };

MagnetometerSample _$MagnetometerSampleFromJson(Map<String, dynamic> json) =>
    MagnetometerSample(
      (json['timeStamp'] as num).toInt(),
      (json['x'] as num).toDouble(),
      (json['y'] as num).toDouble(),
      (json['z'] as num).toDouble(),
    );

Map<String, dynamic> _$MagnetometerSampleToJson(MagnetometerSample instance) =>
    <String, dynamic>{
      'timeStamp': instance.timeStamp,
      'x': instance.x,
      'y': instance.y,
      'z': instance.z,
    };
