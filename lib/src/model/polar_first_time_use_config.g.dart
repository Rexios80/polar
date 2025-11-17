// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: document_ignores, unnecessary_cast, require_trailing_commas, rexios_lints/not_null_assertion

part of 'polar_first_time_use_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$PolarFirstTimeUseConfigToJson(
  PolarFirstTimeUseConfig instance,
) => <String, dynamic>{
  'gender': _genderToJson(instance.gender),
  'birthDate': const UnixTimeConverter().toJson(instance.birthDate),
  'height': instance.height,
  'weight': instance.weight,
  'maxHeartRate': instance.maxHeartRate,
  'vo2Max': instance.vo2Max,
  'restingHeartRate': instance.restingHeartRate,
  'trainingBackground': _trainingBackgroundToJson(instance.trainingBackground),
  'deviceTime': instance.deviceTime.toIso8601String(),
  'typicalDay': _typicalDayToJson(instance.typicalDay),
  'sleepGoalMinutes': instance.sleepGoalMinutes,
};
