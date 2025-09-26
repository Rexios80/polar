/// Represents activity information from a Polar device.
class PolarActivityInfo {
  /// The timestamp when the activity was recorded.
  final DateTime timeStamp;

  /// The activity class (e.g., SEDENTARY, LIGHT, CONTINUOUS_MODERATE, etc.).
  final String? activityClass;

  /// The activity factor value.
  final double? factor;

  /// Creates a new [PolarActivityInfo] instance.
  PolarActivityInfo({
    required this.timeStamp,
    this.activityClass,
    this.factor,
  });

  /// Creates a [PolarActivityInfo] instance from a JSON map.
  factory PolarActivityInfo.fromJson(Map<String, dynamic> json) {
    return PolarActivityInfo(
      timeStamp: DateTime.parse(json['timeStamp']),
      activityClass: json['activityClass'] as String?,
      factor:
          json['factor'] != null ? (json['factor'] as num).toDouble() : null,
    );
  }

  /// Converts this [PolarActivityInfo] instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'timeStamp': timeStamp.toIso8601String(),
      if (activityClass != null) 'activityClass': activityClass,
      if (factor != null) 'factor': factor,
    };
  }

  @override
  String toString() {
    return 'PolarActivityInfo(timeStamp: $timeStamp, activityClass: $activityClass, factor: $factor)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PolarActivityInfo &&
        other.timeStamp == timeStamp &&
        other.activityClass == activityClass &&
        other.factor == factor;
  }

  @override
  int get hashCode => Object.hash(timeStamp, activityClass, factor);
}
