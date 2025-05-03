/// Represents an active time period with detailed time components.
class PolarActiveTime {
  /// Hours component of the active time.
  final int? hours;

  /// Minutes component of the active time.
  final int? minutes;

  /// Seconds component of the active time.
  final int? seconds;

  /// Milliseconds component of the active time.
  final int? millis;

  /// Creates a new [PolarActiveTime] instance.
  PolarActiveTime({
    this.hours,
    this.minutes,
    this.seconds,
    this.millis,
  });

  /// Creates a [PolarActiveTime] instance from a JSON map.
  factory PolarActiveTime.fromJson(Map<String, dynamic> json) {
    return PolarActiveTime(
      hours: json['hours'] as int?,
      minutes: json['minutes'] as int?,
      seconds: json['seconds'] as int?,
      millis: json['millis'] as int?,
    );
  }

  /// Converts this [PolarActiveTime] instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      if (hours != null) 'hours': hours,
      if (minutes != null) 'minutes': minutes,
      if (seconds != null) 'seconds': seconds,
      if (millis != null) 'millis': millis,
    };
  }

  /// Calculate the total duration in seconds.
  double get totalSeconds {
    double total = 0;
    if (hours != null) total += hours! * 3600;
    if (minutes != null) total += minutes! * 60;
    if (seconds != null) total += seconds!;
    if (millis != null) total += millis! / 1000;
    return total;
  }
}
