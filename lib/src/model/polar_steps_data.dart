/// Represents steps data for a specific date from a Polar device.
class PolarStepsData {
  /// The date for which the steps data is recorded.
  final DateTime date;

  /// The number of steps recorded for the date.
  final int steps;

  /// Creates a new [PolarStepsData] instance.
  PolarStepsData({
    required this.date,
    required this.steps,
  });

  /// Creates a [PolarStepsData] instance from a JSON map.
  factory PolarStepsData.fromJson(Map<String, dynamic> json) {
    return PolarStepsData(
      date: DateTime.parse(json['date']),
      steps: json['steps'] as int,
    );
  }

  /// Converts this [PolarStepsData] instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'steps': steps,
    };
  }
}
