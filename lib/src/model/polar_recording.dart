import 'dart:io';

///  Recoding intervals for H10 recording start
enum RecordingInterval {
  /// 1 second interval
  interval1s,

  /// 5 second interval
  interval5s;

  /// Create an [RecordingInterval] from json
  static RecordingInterval fromJson(dynamic json) {
    switch (json as int) {
      case 1:
        return RecordingInterval.interval1s;
      case 5:
        return RecordingInterval.interval5s;
      default:
        throw Exception('Unknown RecordingInterval: $json');
    }
  }

  /// Convert a [RecordingInterval] to json
  dynamic toJson() {
    return RecordingInterval.values.indexOf(this);
  }
}

/// Sample types for H10 recording start
enum SampleType {
  /// recording type to use is hr in BPM
  hr,

  /// recording type to use is rr interval
  rr;

  /// Create a [SampleType] from json
  static SampleType fromJson(dynamic json) {
    if (Platform.isIOS) {
      return SampleType.values[json as int];
    } else {
      // This is android
      return SampleType.values.byName((json as String).toLowerCase());
    }
  }

  /// Convert a [SampleType] to json
  dynamic toJson() {
    if (Platform.isIOS) {
      return SampleType.values.indexOf(this);
    } else {
      // This is Android
      return name.toUpperCase();
    }
  }
}

/// Polar Recording status
class PolarRecordingStatus {
  /// true recording running
  final bool ongoing;

  /// unique identifier
  final String entryId;

  /// Constructor
  PolarRecordingStatus({
    required this.ongoing,
    required this.entryId,
  });
}

/// Polar exercise entry
class PolarExerciseEntry {
  /// Resource location in the device
  final String path;

  /// Entry date and time. Only OH1 and Polar Verity Sense supports date and time
  final DateTime date;

  /// unique identifier
  final String entryId;

  /// Constructor
  PolarExerciseEntry({
    required this.path,
    required this.date,
    required this.entryId,
  });

  /// Create a [PolarExerciseEntry] from json
  PolarExerciseEntry.fromJson(Map<String, dynamic> json)
      : path = json['path'],
        date = DateTime.fromMillisecondsSinceEpoch(json['date']),
        entryId = json['entryId'];
}
