import 'dart:io';

import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:polar/src/model/convert.dart';
import 'package:recase/recase.dart';

part 'polar_first_time_use_config.g.dart';

/// Enum representing the training background levels
enum FtuTrainingBackground {
  /// Occasional training (1-2 times per week)
  occasional(10),

  /// Regular training (2-3 times per week)
  regular(20),

  /// Frequent training (3-4 times per week)
  frequent(30),

  /// Heavy training (4-5 times per week)
  heavy(40),

  /// Semi-professional training (5-6 times per week)
  semiPro(50),

  /// Professional training (6+ times per week)
  pro(60);

  /// The numeric value representing the training background level
  final int value;

  /// Constructor
  const FtuTrainingBackground(this.value);
}

/// Enum representing the typical day activity levels
enum FtuTypicalDay {
  /// Mostly moving throughout the day
  mostlyMoving(1),

  /// Mostly sitting throughout the day
  mostlySitting(2),

  /// Mostly standing throughout the day
  mostlyStanding(3);

  /// The numeric value representing the typical day activity level
  final int value;

  /// Constructor
  const FtuTypicalDay(this.value);
}

/// Enum representing the gender of the user
enum FtuGender {
  /// Male
  male,

  /// Female
  female,
}

/// Configuration class for First Time Use setup
@JsonSerializable(createFactory: false)
@immutable
class PolarFirstTimeUseConfig {
  /// The gender of the user
  @JsonKey(toJson: _genderToJson)
  final FtuGender gender;

  /// The user's birth date
  @UnixTimeConverter()
  final DateTime birthDate;

  /// The user's height in centimeters (90-240)
  final int height;

  /// The user's weight in kilograms (15-300)
  final int weight;

  /// The user's maximum heart rate in bpm (100-240)
  final int maxHeartRate;

  /// The user's VO2 max (10-95)
  final int vo2Max;

  /// The user's resting heart rate in bpm (20-120)
  final int restingHeartRate;

  /// The user's training background level
  @JsonKey(toJson: _trainingBackgroundToJson)
  final FtuTrainingBackground trainingBackground;

  /// The device time in ISO 8601 format
  final DateTime deviceTime;

  /// The user's typical daily activity level
  @JsonKey(toJson: _typicalDayToJson)
  final FtuTypicalDay typicalDay;

  /// The user's sleep goal in minutes
  final int sleepGoalMinutes;

  /// Creates a new [PolarFirstTimeUseConfig] instance
  const PolarFirstTimeUseConfig({
    required this.gender,
    required this.birthDate,
    required this.height,
    required this.weight,
    required this.maxHeartRate,
    required this.vo2Max,
    required this.restingHeartRate,
    required this.trainingBackground,
    required this.deviceTime,
    required this.typicalDay,
    required this.sleepGoalMinutes,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$PolarFirstTimeUseConfigToJson(this);
}

String _genderToJson(FtuGender gender) => gender.name.toUpperCase();
Object _trainingBackgroundToJson(FtuTrainingBackground trainingBackground) =>
    trainingBackground.value;
Object _typicalDayToJson(FtuTypicalDay typicalDay) {
  if (Platform.isIOS) {
    return typicalDay.value;
  } else {
    // This is android
    return typicalDay.name.snakeCase.toUpperCase();
  }
}
