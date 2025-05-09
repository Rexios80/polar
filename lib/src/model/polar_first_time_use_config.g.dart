// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: document_ignores, unnecessary_cast, require_trailing_commas

part of 'polar_first_time_use_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PolarFirstTimeUseConfig _$PolarFirstTimeUseConfigFromJson(
        Map<String, dynamic> json) =>
    PolarFirstTimeUseConfig(
      gender: json['gender'] as String,
      birthDate: DateTime.parse(json['birthDate'] as String),
      height: (json['height'] as num).toInt(),
      weight: (json['weight'] as num).toInt(),
      maxHeartRate: (json['maxHeartRate'] as num).toInt(),
      vo2Max: (json['vo2Max'] as num).toInt(),
      restingHeartRate: (json['restingHeartRate'] as num).toInt(),
      trainingBackground:
          $enumDecode(_$TrainingBackgroundEnumMap, json['trainingBackground']),
      deviceTime: json['deviceTime'] as String,
      typicalDay: $enumDecode(_$TypicalDayEnumMap, json['typicalDay']),
      sleepGoalMinutes: (json['sleepGoalMinutes'] as num).toInt(),
    );

Map<String, dynamic> _$PolarFirstTimeUseConfigToJson(
        PolarFirstTimeUseConfig instance) =>
    <String, dynamic>{
      'gender': instance.gender,
      'birthDate': instance.birthDate.toIso8601String(),
      'height': instance.height,
      'weight': instance.weight,
      'maxHeartRate': instance.maxHeartRate,
      'vo2Max': instance.vo2Max,
      'restingHeartRate': instance.restingHeartRate,
      'trainingBackground':
          _$TrainingBackgroundEnumMap[instance.trainingBackground]!,
      'deviceTime': instance.deviceTime,
      'typicalDay': _$TypicalDayEnumMap[instance.typicalDay]!,
      'sleepGoalMinutes': instance.sleepGoalMinutes,
    };

const _$TrainingBackgroundEnumMap = {
  TrainingBackground.occasional: 'occasional',
  TrainingBackground.regular: 'regular',
  TrainingBackground.frequent: 'frequent',
  TrainingBackground.heavy: 'heavy',
  TrainingBackground.semiPro: 'semiPro',
  TrainingBackground.pro: 'pro',
};

const _$TypicalDayEnumMap = {
  TypicalDay.mostlyMoving: 'mostlyMoving',
  TypicalDay.mostlySitting: 'mostlySitting',
  TypicalDay.mostlyStanding: 'mostlyStanding',
};
