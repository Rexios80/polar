// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: document_ignores, unnecessary_cast, require_trailing_commas

part of 'polar_offline_recording_trigger.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PolarOfflineRecordingTrigger _$PolarOfflineRecordingTriggerFromJson(
        Map<String, dynamic> json) =>
    PolarOfflineRecordingTrigger(
      triggerMode: $enumDecode(
          _$PolarOfflineRecordingTriggerModeEnumMap, json['triggerMode']),
      triggerFeatures: (json['triggerFeatures'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(
            $enumDecode(_$PolarDataTypeEnumMap, k),
            e == null
                ? null
                : PolarSensorSetting.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$PolarOfflineRecordingTriggerToJson(
        PolarOfflineRecordingTrigger instance) =>
    <String, dynamic>{
      'triggerMode':
          _$PolarOfflineRecordingTriggerModeEnumMap[instance.triggerMode]!,
      'triggerFeatures': instance.triggerFeatures
          .map((k, e) => MapEntry(k.toJson(), e?.toJson())),
    };

const _$PolarOfflineRecordingTriggerModeEnumMap = {
  PolarOfflineRecordingTriggerMode.triggerDisabled: 0,
  PolarOfflineRecordingTriggerMode.triggerSystemStart: 1,
  PolarOfflineRecordingTriggerMode.triggerExerciseStart: 2,
};

const _$PolarDataTypeEnumMap = {
  PolarDataType.ecg: 'ecg',
  PolarDataType.acc: 'acc',
  PolarDataType.ppg: 'ppg',
  PolarDataType.ppi: 'ppi',
  PolarDataType.gyro: 'gyro',
  PolarDataType.magnetometer: 'magnetometer',
  PolarDataType.hr: 'hr',
  PolarDataType.temperature: 'temperature',
  PolarDataType.pressure: 'pressure',
};
