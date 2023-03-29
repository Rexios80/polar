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

Map<String, dynamic> _$PolarStreamingDataToJson<T>(
  PolarStreamingData<T> instance,
  Object? Function(T value) toJsonT,
) =>
    <String, dynamic>{
      'samples': instance.samples.map(toJsonT).toList(),
    };

PolarHrSample _$PolarHrSampleFromJson(Map<String, dynamic> json) =>
    PolarHrSample(
      hr: json['hr'] as int,
      rrsMs: (json['rrsMs'] as List<dynamic>).map((e) => e as int).toList(),
      contactStatus: json['contactStatus'] as bool,
      contactStatusSupported: json['contactStatusSupported'] as bool,
    );

Map<String, dynamic> _$PolarHrSampleToJson(PolarHrSample instance) =>
    <String, dynamic>{
      'hr': instance.hr,
      'rrsMs': instance.rrsMs,
      'contactStatus': instance.contactStatus,
      'contactStatusSupported': instance.contactStatusSupported,
    };

PolarEcgSample _$PolarEcgSampleFromJson(Map<String, dynamic> json) =>
    PolarEcgSample(
      timeStamp: const PolarSampleTimestampConverter()
          .fromJson(json['timeStamp'] as int),
      voltage: json['voltage'] as int,
    );

Map<String, dynamic> _$PolarEcgSampleToJson(PolarEcgSample instance) =>
    <String, dynamic>{
      'timeStamp':
          const PolarSampleTimestampConverter().toJson(instance.timeStamp),
      'voltage': instance.voltage,
    };

PolarAccSample _$PolarAccSampleFromJson(Map<String, dynamic> json) =>
    PolarAccSample(
      timeStamp: const PolarSampleTimestampConverter()
          .fromJson(json['timeStamp'] as int),
      x: json['x'] as int,
      y: json['y'] as int,
      z: json['z'] as int,
    );

Map<String, dynamic> _$PolarAccSampleToJson(PolarAccSample instance) =>
    <String, dynamic>{
      'timeStamp':
          const PolarSampleTimestampConverter().toJson(instance.timeStamp),
      'x': instance.x,
      'y': instance.y,
      'z': instance.z,
    };

PolarGyroSample _$PolarGyroSampleFromJson(Map<String, dynamic> json) =>
    PolarGyroSample(
      timeStamp: const PolarSampleTimestampConverter()
          .fromJson(json['timeStamp'] as int),
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      z: (json['z'] as num).toDouble(),
    );

Map<String, dynamic> _$PolarGyroSampleToJson(PolarGyroSample instance) =>
    <String, dynamic>{
      'timeStamp':
          const PolarSampleTimestampConverter().toJson(instance.timeStamp),
      'x': instance.x,
      'y': instance.y,
      'z': instance.z,
    };

PolarMagnetometerSample _$PolarMagnetometerSampleFromJson(
        Map<String, dynamic> json) =>
    PolarMagnetometerSample(
      timeStamp: const PolarSampleTimestampConverter()
          .fromJson(json['timeStamp'] as int),
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      z: (json['z'] as num).toDouble(),
    );

Map<String, dynamic> _$PolarMagnetometerSampleToJson(
        PolarMagnetometerSample instance) =>
    <String, dynamic>{
      'timeStamp':
          const PolarSampleTimestampConverter().toJson(instance.timeStamp),
      'x': instance.x,
      'y': instance.y,
      'z': instance.z,
    };

PolarPpgSample _$PolarPpgSampleFromJson(Map<String, dynamic> json) =>
    PolarPpgSample(
      timeStamp: const PolarSampleTimestampConverter()
          .fromJson(json['timeStamp'] as int),
      channelSamples: (json['channelSamples'] as List<dynamic>)
          .map((e) => e as int)
          .toList(),
    );

Map<String, dynamic> _$PolarPpgSampleToJson(PolarPpgSample instance) =>
    <String, dynamic>{
      'timeStamp':
          const PolarSampleTimestampConverter().toJson(instance.timeStamp),
      'channelSamples': instance.channelSamples,
    };

PolarPpgData _$PolarPpgDataFromJson(Map<String, dynamic> json) => PolarPpgData(
      type: const PpgDataTypeConverter().fromJson(json['type']),
      samples: (json['samples'] as List<dynamic>)
          .map((e) => PolarPpgSample.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PolarPpgDataToJson(PolarPpgData instance) =>
    <String, dynamic>{
      'samples': instance.samples,
      'type': const PpgDataTypeConverter().toJson(instance.type),
    };

PolarPpiSample _$PolarPpiSampleFromJson(Map<String, dynamic> json) =>
    PolarPpiSample(
      ppi: _readPpi(json, 'ppi') as int,
      errorEstimate: _readErrorEstimate(json, 'errorEstimate') as int,
      hr: json['hr'] as int,
      blockerBit: const PlatformBooleanConverter().fromJson(json['blockerBit']),
      skinContactStatus:
          const PlatformBooleanConverter().fromJson(json['skinContactStatus']),
      skinContactSupported: const PlatformBooleanConverter()
          .fromJson(json['skinContactSupported']),
    );

Map<String, dynamic> _$PolarPpiSampleToJson(PolarPpiSample instance) =>
    <String, dynamic>{
      'ppi': instance.ppi,
      'errorEstimate': instance.errorEstimate,
      'hr': instance.hr,
      'blockerBit':
          const PlatformBooleanConverter().toJson(instance.blockerBit),
      'skinContactStatus':
          const PlatformBooleanConverter().toJson(instance.skinContactStatus),
      'skinContactSupported': const PlatformBooleanConverter()
          .toJson(instance.skinContactSupported),
    };
