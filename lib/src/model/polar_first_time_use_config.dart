// ignoring because android uses the enum names as all caps, so our enum names should be too
// ignore_for_file: constant_identifier_names

import 'package:json_annotation/json_annotation.dart';

part 'polar_first_time_use_config.g.dart';

/// Config for the first time use of the Polar device
@JsonSerializable()
class PolarFirstTimeUseConfig {
  /// Gender of the user
  final Gender gender;

  /// Date of birth, in ms since epoch
  final String birthDate;

  /// Height of the user in centimeters
  final double height;

  /// Weight of the user in kilograms
  final double weight;

  /// Maximum heart rate of the user
  final int maxHeartRate;

  /// VO2 Max value of the user
  final int vo2Max;

  /// Resting heart rate of the user
  final int restingHeartRate;

  /// Training background of the user
  final int trainingBackground;

  /// Device time in string format
  final String deviceTime;

  /// Typical day activity level of the user
  final TypicalDay typicalDay;

  /// Sleep goal in minutes
  final int sleepGoalMinutes;

  /// Constructor
  PolarFirstTimeUseConfig({
    this.gender = Gender.MALE,
    required this.birthDate,
    required this.trainingBackground,
    required this.deviceTime,
    this.typicalDay = TypicalDay.MOSTLY_STANDING,
    this.height = 173,
    this.weight = 70,
    this.maxHeartRate = 220,
    this.vo2Max = 50,
    this.restingHeartRate = 60,
    this.sleepGoalMinutes = 480,
  });

  /// Factory method to create an instance from JSON
  factory PolarFirstTimeUseConfig.fromJson(Map<String, dynamic> json) =>
      _$PolarFirstTimeUseConfigFromJson(json);

  /// Method to convert an instance to JSON
  Map<String, dynamic> toJson() => _$PolarFirstTimeUseConfigToJson(this);
}

/// Gender enum
enum Gender {
  /// male
  MALE,

  /// female
  FEMALE,
}

/// Training background enum with associated values
enum TrainingBackground {
  /// occasional
  occasional(10),

  /// regular
  regular(20),

  /// frequent

  frequent(30),

  /// heavy
  heavy(40),

  /// semi pro
  semiPro(50),

  /// pro
  pro(60);

  /// value associated with the enum
  final int value;

  const TrainingBackground(this.value);
}

/// Typical day activity level enum with associated values and names
enum TypicalDay {
  /// sitting
  MOSTLY_SITTING(1, 'Mostly Sitting'),

  /// standing
  MOSTLY_STANDING(2, 'Mostly Standing'),

  /// moving
  MOSTLY_MOVING(3, 'Mostly Moving');

  /// value associated with the enum
  final int value;

  /// name of the typical day
  final String name;

  const TypicalDay(this.value, this.name);
}
