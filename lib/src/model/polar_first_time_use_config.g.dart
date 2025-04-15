// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: document_ignores, unnecessary_cast, require_trailing_commas

part of 'polar_first_time_use_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PolarFirstTimeUseConfig _$PolarFirstTimeUseConfigFromJson(
        Map<String, dynamic> json) =>
    PolarFirstTimeUseConfig(
      gender:
          $enumDecodeNullable(_$GenderEnumMap, json['gender']) ?? Gender.MALE,
      birthDate: json['birthDate'] as String,
      trainingBackground: (json['trainingBackground'] as num).toInt(),
      deviceTime: json['deviceTime'] as String,
      height: (json['height'] as num?)?.toDouble() ?? 165,
      weight: (json['weight'] as num?)?.toDouble() ?? 70,
      maxHeartRate: (json['maxHeartRate'] as num?)?.toInt() ?? 220,
      vo2Max: (json['vo2Max'] as num?)?.toInt() ?? 40,
      restingHeartRate: (json['restingHeartRate'] as num?)?.toInt() ?? 60,
      typicalDay:
          $enumDecodeNullable(_$TypicalDayEnumMap, json['typicalDay']) ??
              TypicalDay.MOSTLY_SITTING,
      sleepGoalMinutes: (json['sleepGoalMinutes'] as num?)?.toInt() ?? 480,
    );

Map<String, dynamic> _$PolarFirstTimeUseConfigToJson(
        PolarFirstTimeUseConfig instance) =>
    <String, dynamic>{
      'gender': _$GenderEnumMap[instance.gender]!,
      'birthDate': instance.birthDate,
      'height': instance.height,
      'weight': instance.weight,
      'maxHeartRate': instance.maxHeartRate,
      'vo2Max': instance.vo2Max,
      'restingHeartRate': instance.restingHeartRate,
      'trainingBackground': instance.trainingBackground,
      'deviceTime': instance.deviceTime,
      'typicalDay': _$TypicalDayEnumMap[instance.typicalDay]!,
      'sleepGoalMinutes': instance.sleepGoalMinutes,
    };

const _$GenderEnumMap = {
  Gender.MALE: 'MALE',
  Gender.FEMALE: 'FEMALE',
};

const _$TypicalDayEnumMap = {
  TypicalDay.MOSTLY_SITTING: 'MOSTLY_SITTING',
  TypicalDay.MOSTLY_STANDING: 'MOSTLY_STANDING',
  TypicalDay.MOSTLY_MOVING: 'MOSTLY_MOVING',
};
