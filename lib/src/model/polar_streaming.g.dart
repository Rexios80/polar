// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: unnecessary_cast, require_trailing_commas

part of 'polar_streaming.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PolarEcgSample _$PolarEcgSampleFromJson(Map<String, dynamic> json) =>
    PolarEcgSample(
      timeStamp: json['timeStamp'] as int,
      voltage: json['voltage'] as int,
    );

PolarEcgData _$PolarEcgDataFromJson(Map<String, dynamic> json) => PolarEcgData(
      samples: (json['samples'] as List<dynamic>)
          .map((e) => PolarEcgSample.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

PolarAccSample _$PolarAccSampleFromJson(Map<String, dynamic> json) =>
    PolarAccSample(
      timeStamp: json['timeStamp'] as int,
      x: json['x'] as int,
      y: json['y'] as int,
      z: json['z'] as int,
    );

PolarAccData _$PolarAccDataFromJson(Map<String, dynamic> json) => PolarAccData(
      samples: (json['samples'] as List<dynamic>)
          .map((e) => PolarAccSample.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

PolarGyroSample _$PolarGyroSampleFromJson(Map<String, dynamic> json) =>
    PolarGyroSample(
      timeStamp: json['timeStamp'] as int,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      z: (json['z'] as num).toDouble(),
    );

PolarGyroData _$PolarGyroDataFromJson(Map<String, dynamic> json) =>
    PolarGyroData(
      samples: (json['samples'] as List<dynamic>)
          .map((e) => PolarGyroSample.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

PolarMagnetometerSample _$PolarMagnetometerSampleFromJson(
        Map<String, dynamic> json) =>
    PolarMagnetometerSample(
      timeStamp: json['timeStamp'] as int,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      z: (json['z'] as num).toDouble(),
    );

PolarMagnetometerData _$PolarMagnetometerDataFromJson(
        Map<String, dynamic> json) =>
    PolarMagnetometerData(
      samples: (json['samples'] as List<dynamic>)
          .map((e) =>
              PolarMagnetometerSample.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

PolarOhrSample _$PolarOhrSampleFromJson(Map<String, dynamic> json) =>
    PolarOhrSample(
      timeStamp: json['timeStamp'] as int,
      channelSamples: (json['channelSamples'] as List<dynamic>)
          .map((e) => e as int)
          .toList(),
    );

PolarOhrData _$PolarOhrDataFromJson(Map<String, dynamic> json) => PolarOhrData(
      type: const OhrDataTypeConverter().fromJson(json['type']),
      samples: (json['samples'] as List<dynamic>)
          .map((e) => PolarOhrSample.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

PolarPpiSample _$PolarPpiSampleFromJson(Map<String, dynamic> json) =>
    PolarPpiSample(
      ppi: json['ppi'] as int,
      errorEstimate: json['errorEstimate'] as int,
      hr: json['hr'] as int,
      blockerBit: const PlatformBooleanConverter().fromJson(json['blockerBit']),
      skinContactStatus:
          const PlatformBooleanConverter().fromJson(json['skinContactStatus']),
      skinContactSupported: const PlatformBooleanConverter()
          .fromJson(json['skinContactSupported']),
    );

PolarOhrPpiData _$PolarPpiDataFromJson(Map<String, dynamic> json) =>
    PolarOhrPpiData(
      samples: (json['samples'] as List<dynamic>)
          .map((e) => PolarPpiSample.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
