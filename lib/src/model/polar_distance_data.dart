/// Represents distance data for a specific date from a Polar device.
class PolarDistanceData {
  /// The date for which the distance data is recorded.
  final DateTime date;

  /// The distance recorded for the date in meters.
  final double distanceMeters;

  /// Creates a new [PolarDistanceData] instance.
  PolarDistanceData({
    required this.date,
    required this.distanceMeters,
  });

  /// Creates a [PolarDistanceData] instance from a JSON map.
  factory PolarDistanceData.fromJson(Map<String, dynamic> json) {
    return PolarDistanceData(
      date: DateTime.parse(json['date']),
      distanceMeters: (json['distanceMeters'] as num).toDouble(),
    );
  }

  /// Converts this [PolarDistanceData] instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'distanceMeters': distanceMeters,
    };
  }
}
