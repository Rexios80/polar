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
          $enumDecodeNullable(_$GenderEnumMap, json['gender']) ?? Gender.male,
      birthDate: DateTime.parse(json['birthDate'] as String),
      trainingBackground: (json['trainingBackground'] as num).toInt(),
      height: (json['height'] as num?)?.toDouble() ?? 165,
      weight: (json['weight'] as num?)?.toDouble() ?? 70,
      maxHeartRate: (json['maxHeartRate'] as num?)?.toInt() ?? 220,
      vo2Max: (json['vo2Max'] as num?)?.toInt() ?? 40,
      restingHeartRate: (json['restingHeartRate'] as num?)?.toInt() ?? 60,
      deviceTime: json['deviceTime'] as String? ?? '',
      typicalDay:
          $enumDecodeNullable(_$TypicalDayEnumMap, json['typicalDay']) ??
              TypicalDay.mostlySitting,
      sleepGoalMinutes: (json['sleepGoalMinutes'] as num?)?.toInt() ?? 480,
    );

Map<String, dynamic> _$PolarFirstTimeUseConfigToJson(
        PolarFirstTimeUseConfig instance) =>
    <String, dynamic>{
      'gender': _$GenderEnumMap[instance.gender]!,
      'birthDate': instance.birthDate.toIso8601String(),
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
  Gender.male: 'male',
  Gender.female: 'female',
};

const _$TypicalDayEnumMap = {
  TypicalDay.mostlySitting: 'mostlySitting',
  TypicalDay.mostlyStanding: 'mostlyStanding',
  TypicalDay.mostlyMoving: 'mostlyMoving',
};
