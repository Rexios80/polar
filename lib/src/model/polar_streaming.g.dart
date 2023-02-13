// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: unnecessary_cast, require_trailing_commas

part of 'polar_streaming.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PolarStreamingData<T> _$PolarStreamingDataFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) =>
    PolarStreamingData<T>(
      samples: (json['samples'] as List<dynamic>).map(fromJsonT).toList(),
    );

PolarHrSample _$PolarHrSampleFromJson(Map<String, dynamic> json) =>
    PolarHrSample(
      timeStamp: json['timeStamp'] as int,
      hr: json['hr'] as int,
      rrs: (json['rrs'] as List<dynamic>).map((e) => e as int).toList(),
      rrsMs: (json['rrsMs'] as List<dynamic>).map((e) => e as int).toList(),
      contactStatus:
          PolarHrSample._readContactStatus(json, 'contactStatus') as bool,
      contactStatusSupported: PolarHrSample._readContactStatusSupported(
          json, 'contactStatusSupported') as bool,
    );

PolarEcgSample _$PolarEcgSampleFromJson(Map<String, dynamic> json) =>
    PolarEcgSample(
      timeStamp: json['timeStamp'] as int,
      voltage: json['voltage'] as int,
    );

PolarAccSample _$PolarAccSampleFromJson(Map<String, dynamic> json) =>
    PolarAccSample(
      timeStamp: json['timeStamp'] as int,
      x: json['x'] as int,
      y: json['y'] as int,
      z: json['z'] as int,
    );

PolarGyroSample _$PolarGyroSampleFromJson(Map<String, dynamic> json) =>
    PolarGyroSample(
      timeStamp: json['timeStamp'] as int,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      z: (json['z'] as num).toDouble(),
    );

PolarMagnetometerSample _$PolarMagnetometerSampleFromJson(
        Map<String, dynamic> json) =>
    PolarMagnetometerSample(
      timeStamp: json['timeStamp'] as int,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      z: (json['z'] as num).toDouble(),
    );

PolarPpgSample _$PolarPpgSampleFromJson(Map<String, dynamic> json) =>
    PolarPpgSample(
      timeStamp: json['timeStamp'] as int,
      channelSamples: (json['channelSamples'] as List<dynamic>)
          .map((e) => e as int)
          .toList(),
    );

PolarPpgData _$PolarPpgDataFromJson(Map<String, dynamic> json) => PolarPpgData(
      type: const PpgDataTypeConverter().fromJson(json['type']),
      samples: (json['samples'] as List<dynamic>)
          .map((e) => PolarPpgSample.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

PolarPpiSample _$PolarPpiSampleFromJson(Map<String, dynamic> json) =>
    PolarPpiSample(
      ppi: PolarPpiSample._readPpi(json, 'ppi') as int,
      errorEstimate:
          PolarPpiSample._readErrorEstimate(json, 'errorEstimate') as int,
      hr: json['hr'] as int,
      blockerBit: const PlatformBooleanConverter().fromJson(json['blockerBit']),
      skinContactStatus:
          const PlatformBooleanConverter().fromJson(json['skinContactStatus']),
      skinContactSupported: const PlatformBooleanConverter()
          .fromJson(json['skinContactSupported']),
    );
