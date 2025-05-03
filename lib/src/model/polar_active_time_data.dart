import 'polar_active_time.dart';

/// Represents detailed active time data for a specific date from a Polar device.
class PolarActiveTimeData {
  /// The date for which the active time data is recorded.
  final DateTime date;

  /// Time spent not wearing the device.
  final PolarActiveTime? timeNonWear;

  /// Time spent sleeping.
  final PolarActiveTime? timeSleep;

  /// Time spent in sedentary activities.
  final PolarActiveTime? timeSedentary;

  /// Time spent in light activities.
  final PolarActiveTime? timeLightActivity;

  /// Time spent in continuous moderate activities.
  final PolarActiveTime? timeContinuousModerateActivity;

  /// Time spent in intermittent moderate activities.
  final PolarActiveTime? timeIntermittentModerateActivity;

  /// Time spent in continuous vigorous activities.
  final PolarActiveTime? timeContinuousVigorousActivity;

  /// Time spent in intermittent vigorous activities.
  final PolarActiveTime? timeIntermittentVigorousActivity;

  /// Creates a new [PolarActiveTimeData] instance.
  PolarActiveTimeData({
    required this.date,
    this.timeNonWear,
    this.timeSleep,
    this.timeSedentary,
    this.timeLightActivity,
    this.timeContinuousModerateActivity,
    this.timeIntermittentModerateActivity,
    this.timeContinuousVigorousActivity,
    this.timeIntermittentVigorousActivity,
  });

  /// Creates a [PolarActiveTimeData] instance from a JSON map.
  factory PolarActiveTimeData.fromJson(Map<String, dynamic> json) {
    return PolarActiveTimeData(
      date: DateTime.parse(json['date']),
      timeNonWear: json['timeNonWear'] != null
          ? PolarActiveTime.fromJson(json['timeNonWear'])
          : null,
      timeSleep: json['timeSleep'] != null
          ? PolarActiveTime.fromJson(json['timeSleep'])
          : null,
      timeSedentary: json['timeSedentary'] != null
          ? PolarActiveTime.fromJson(json['timeSedentary'])
          : null,
      timeLightActivity: json['timeLightActivity'] != null
          ? PolarActiveTime.fromJson(json['timeLightActivity'])
          : null,
      timeContinuousModerateActivity:
          json['timeContinuousModerateActivity'] != null
              ? PolarActiveTime.fromJson(json['timeContinuousModerateActivity'])
              : null,
      timeIntermittentModerateActivity:
          json['timeIntermittentModerateActivity'] != null
              ? PolarActiveTime.fromJson(
                  json['timeIntermittentModerateActivity'])
              : null,
      timeContinuousVigorousActivity:
          json['timeContinuousVigorousActivity'] != null
              ? PolarActiveTime.fromJson(json['timeContinuousVigorousActivity'])
              : null,
      timeIntermittentVigorousActivity:
          json['timeIntermittentVigorousActivity'] != null
              ? PolarActiveTime.fromJson(
                  json['timeIntermittentVigorousActivity'])
              : null,
    );
  }

  /// Converts this [PolarActiveTimeData] instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      if (timeNonWear != null) 'timeNonWear': timeNonWear!.toJson(),
      if (timeSleep != null) 'timeSleep': timeSleep!.toJson(),
      if (timeSedentary != null) 'timeSedentary': timeSedentary!.toJson(),
      if (timeLightActivity != null)
        'timeLightActivity': timeLightActivity!.toJson(),
      if (timeContinuousModerateActivity != null)
        'timeContinuousModerateActivity':
            timeContinuousModerateActivity!.toJson(),
      if (timeIntermittentModerateActivity != null)
        'timeIntermittentModerateActivity':
            timeIntermittentModerateActivity!.toJson(),
      if (timeContinuousVigorousActivity != null)
        'timeContinuousVigorousActivity':
            timeContinuousVigorousActivity!.toJson(),
      if (timeIntermittentVigorousActivity != null)
        'timeIntermittentVigorousActivity':
            timeIntermittentVigorousActivity!.toJson(),
    };
  }
}
