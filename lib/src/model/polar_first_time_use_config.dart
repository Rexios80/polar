/// Enum representing the training background levels
enum TrainingBackground {
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
  const TrainingBackground(this.value);
}

/// Enum representing the typical day activity levels
enum TypicalDay {
  /// Mostly moving throughout the day
  mostlyMoving(1),

  /// Mostly sitting throughout the day
  mostlySitting(2),

  /// Mostly standing throughout the day
  mostlyStanding(3);

  /// The numeric value representing the typical day activity level
  final int value;
  const TypicalDay(this.value);
}

/// Configuration class for First Time Use setup
class PolarFirstTimeUseConfig {
  /// The gender of the user ('Male' or 'Female')
  final String gender;

  /// The user's birth date
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
  final TrainingBackground trainingBackground;

  /// The device time in ISO 8601 format
  final String deviceTime;

  /// The user's typical daily activity level
  final TypicalDay typicalDay;

  /// The user's sleep goal in minutes
  final int sleepGoalMinutes;

  /// Creates a new [PolarFirstTimeUseConfig] instance
  PolarFirstTimeUseConfig({
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
  }) {
    // Validate ranges
    if (height < 90 || height > 240) {
      throw ArgumentError('Height must be between 90 and 240 cm');
    }
    if (weight < 15 || weight > 300) {
      throw ArgumentError('Weight must be between 15 and 300 kg');
    }
    if (maxHeartRate < 100 || maxHeartRate > 240) {
      throw ArgumentError('Max heart rate must be between 100 and 240 bpm');
    }
    if (restingHeartRate < 20 || restingHeartRate > 120) {
      throw ArgumentError('Resting heart rate must be between 20 and 120 bpm');
    }
    if (vo2Max < 10 || vo2Max > 95) {
      throw ArgumentError('VO2 max must be between 10 and 95');
    }
    if (!['Male', 'Female'].contains(gender)) {
      throw ArgumentError('Gender must be either "Male" or "Female"');
    }
  }

  /// Converts this configuration to a map for JSON serialization
  Map<String, dynamic> toMap() {
    return {
      'gender': gender,
      'birthDate': birthDate.toIso8601String().split('T')[0],
      'height': height,
      'weight': weight,
      'maxHeartRate': maxHeartRate,
      'vo2Max': vo2Max,
      'restingHeartRate': restingHeartRate,
      'trainingBackground': trainingBackground.value,
      'deviceTime': deviceTime,
      'typicalDay': typicalDay.value,
      'sleepGoalMinutes': sleepGoalMinutes,
    };
  }
}

// final config = PolarFirstTimeUseConfig(
//   gender: 'Male',
//   birthDate: DateTime(1990, 1, 1),
//   height: 180,
//   weight: 75,
//   maxHeartRate: 180,
//   vo2Max: 50,
//   restingHeartRate: 60,
//   trainingBackground: TrainingBackground.occasional,
//   deviceTime: '2025-01-24T12:00:00Z',
//   typicalDay: TypicalDay.normal,
//   sleepGoalMinutes: 480,
// );

// await doFirstTimeUse('deviceId', config);
