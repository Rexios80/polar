// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: document_ignores, unnecessary_cast, require_trailing_commas

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
      hr: (json['hr'] as num).toInt(),
      ppgQuality: (json['ppgQuality'] as num).toInt(),
      correctedHr: (json['correctedHr'] as num).toInt(),
      rrsMs: (json['rrsMs'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      contactStatus: json['contactStatus'] as bool,
      contactStatusSupported: json['contactStatusSupported'] as bool,
    );

Map<String, dynamic> _$PolarHrSampleToJson(PolarHrSample instance) =>
    <String, dynamic>{
      'hr': instance.hr,
      'ppgQuality': instance.ppgQuality,
      'correctedHr': instance.correctedHr,
      'rrsMs': instance.rrsMs,
      'contactStatus': instance.contactStatus,
      'contactStatusSupported': instance.contactStatusSupported,
    };

PolarEcgSample _$PolarEcgSampleFromJson(Map<String, dynamic> json) =>
    PolarEcgSample(
      timeStamp: const PolarSampleTimestampConverter()
          .fromJson((json['timeStamp'] as num).toInt()),
      voltage: (json['voltage'] as num).toInt(),
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
          .fromJson((json['timeStamp'] as num).toInt()),
      x: (json['x'] as num).toInt(),
      y: (json['y'] as num).toInt(),
      z: (json['z'] as num).toInt(),
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
          .fromJson((json['timeStamp'] as num).toInt()),
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
          .fromJson((json['timeStamp'] as num).toInt()),
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
          .fromJson((json['timeStamp'] as num).toInt()),
      channelSamples: (json['channelSamples'] as List<dynamic>)
          .map((e) => (e as num).toInt())
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
      timeStamp: (json['timeStamp'] as num).toInt(),
      ppi: (_readPpi(json, 'ppi') as num).toInt(),
      errorEstimate: (_readErrorEstimate(json, 'errorEstimate') as num).toInt(),
      hr: (json['hr'] as num).toInt(),
      blockerBit: const PlatformBooleanConverter().fromJson(json['blockerBit']),
      skinContactStatus:
          const PlatformBooleanConverter().fromJson(json['skinContactStatus']),
      skinContactSupported: const PlatformBooleanConverter()
          .fromJson(json['skinContactSupported']),
    );

Map<String, dynamic> _$PolarPpiSampleToJson(PolarPpiSample instance) =>
    <String, dynamic>{
      'timeStamp': instance.timeStamp,
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

PolarTemperatureSample _$PolarTemperatureSampleFromJson(
        Map<String, dynamic> json) =>
    PolarTemperatureSample(
      timeStamp: const PolarSampleTimestampConverter()
          .fromJson((json['timeStamp'] as num).toInt()),
      temperature: (json['temperature'] as num).toDouble(),
    );

Map<String, dynamic> _$PolarTemperatureSampleToJson(
        PolarTemperatureSample instance) =>
    <String, dynamic>{
      'timeStamp':
          const PolarSampleTimestampConverter().toJson(instance.timeStamp),
      'temperature': instance.temperature,
    };

PolarPressureSample _$PolarPressureSampleFromJson(Map<String, dynamic> json) =>
    PolarPressureSample(
      timeStamp: const PolarSampleTimestampConverter()
          .fromJson((json['timeStamp'] as num).toInt()),
      pressure: (json['pressure'] as num).toDouble(),
    );

Map<String, dynamic> _$PolarPressureSampleToJson(
        PolarPressureSample instance) =>
    <String, dynamic>{
      'timeStamp':
          const PolarSampleTimestampConverter().toJson(instance.timeStamp),
      'pressure': instance.pressure,
    };

PolarLocationDataSample _$PolarLocationDataSampleFromJson(
        Map<String, dynamic> json) =>
    PolarLocationDataSample(
      timeStamp: const PolarSampleTimestampConverter()
          .fromJson((json['timeStamp'] as num).toInt()),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      time: json['time'] as String,
      cumulativeDistance: (json['cumulativeDistance'] as num).toDouble(),
      speed: (json['speed'] as num).toDouble(),
      usedAccelerationSpeed: (json['usedAccelerationSpeed'] as num).toDouble(),
      coordinateSpeed: (json['coordinateSpeed'] as num).toDouble(),
      accelerationSpeedFactor:
          (json['accelerationSpeedFactor'] as num).toDouble(),
      course: (json['course'] as num).toDouble(),
      gpsChipSpeed: (json['gpsChipSpeed'] as num).toDouble(),
      fix: json['fix'] as bool,
      speedFlag: (json['speedFlag'] as num).toInt(),
      fusionState: (json['fusionState'] as num).toInt(),
    );

Map<String, dynamic> _$PolarLocationDataSampleToJson(
        PolarLocationDataSample instance) =>
    <String, dynamic>{
      'timeStamp':
          const PolarSampleTimestampConverter().toJson(instance.timeStamp),
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'time': instance.time,
      'cumulativeDistance': instance.cumulativeDistance,
      'speed': instance.speed,
      'usedAccelerationSpeed': instance.usedAccelerationSpeed,
      'coordinateSpeed': instance.coordinateSpeed,
      'accelerationSpeedFactor': instance.accelerationSpeedFactor,
      'course': instance.course,
      'gpsChipSpeed': instance.gpsChipSpeed,
      'fix': instance.fix,
      'speedFlag': instance.speedFlag,
      'fusionState': instance.fusionState,
    };
