import 'dart:io';

///  Recoding intervals for H10 recording start
enum RecordingInterval {
  /// 1 second interval
  interval_1s,

  /// 5 second interval
  interval_5s;

  /// Convert a [RecordingInterval] to json
  dynamic toJson() {
    if (Platform.isIOS) {
      return RecordingInterval.values.indexOf(this);
    } else {
      return name.toUpperCase();
    }
  }
}

/// Sample types for H10 recording start
enum SampleType {
  /// recording type to use is hr in BPM
  hr,

  /// recording type to use is rr interval
  rr;

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

  @override
  String toString() {
    return 'PolarRecordingStatus(ongoing: $ongoing, entryId: $entryId)';
  }
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
        entryId = Platform.isIOS ? json['entryId'] : json['identifier'];

  /// Convert a [PolarExerciseEntry] to json
  Map<String, dynamic> toJson() => {
        'path': path,
        'date': date.millisecondsSinceEpoch,
        (Platform.isIOS ? 'entryId' : 'identifier'): entryId,
      };

  @override
  String toString() {
    return 'PolarExerciseEntry(path: $path, date: $date, entryId: $entryId)';
  }
}

/// Polar Exercise Data
class PolarExerciseData {
  /// Polar device id
  final String identifier;

  /// in seconds
  final int interval;

  /// List of HR or RR samples in BPM
  final List<int> samples;

  /// Create a [PolarExerciseData] from json
  PolarExerciseData.fromJson(this.identifier, Map<String, dynamic> json)
      : interval = json['interval'],
        samples = (json['samples'] as List).map((e) => e as int).toList();
}
