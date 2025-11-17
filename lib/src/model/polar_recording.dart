import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:polar/src/model/convert.dart';

part 'polar_recording.g.dart';

///  Recoding intervals for H10 recording start
enum RecordingInterval {
  /// 1 second interval
  interval_1s,

  /// 5 second interval
  interval_5s;

  /// Convert a [RecordingInterval] to json
  dynamic toJson() {
    if (Platform.isIOS) {
      switch (this) {
        case RecordingInterval.interval_1s:
          return 1;
        case RecordingInterval.interval_5s:
          return 5;
      }
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
@immutable
class PolarRecordingStatus {
  /// true recording running
  final bool ongoing;

  /// unique identifier
  final String entryId;

  /// Constructor
  const PolarRecordingStatus({required this.ongoing, required this.entryId});

  @override
  String toString() {
    return 'PolarRecordingStatus(ongoing: $ongoing, entryId: $entryId)';
  }
}

/// Polar exercise entry
@JsonSerializable()
@immutable
class PolarExerciseEntry {
  /// Resource location in the device
  final String path;

  /// Entry date and time. Only OH1 and Polar Verity Sense supports date and time
  @UnixTimeConverter()
  final DateTime date;

  /// unique identifier
  @JsonKey(readValue: _readEntryId, includeToJson: false)
  final String entryId;

  /// Constructor
  const PolarExerciseEntry({
    required this.path,
    required this.date,
    required this.entryId,
  });

  /// From json
  factory PolarExerciseEntry.fromJson(Map<String, dynamic> json) =>
      _$PolarExerciseEntryFromJson(json);

  /// To json
  Map<String, dynamic> toJson() => {
    ..._$PolarExerciseEntryToJson(this),
    _entryIdKeys[defaultTargetPlatform]!: entryId,
  };

  @override
  String toString() {
    return 'PolarExerciseEntry(path: $path, date: $date, entryId: $entryId)';
  }
}

const _entryIdKeys = {
  TargetPlatform.iOS: 'entryId',
  TargetPlatform.android: 'identifier',
};

Object? _readEntryId(Map json, String key) =>
    readPlatformValue(json, _entryIdKeys);

/// Polar Exercise Data
@JsonSerializable()
@immutable
class PolarExerciseData {
  /// in seconds
  @JsonKey(readValue: _readInterval)
  final int interval;

  /// List of HR or RR samples in BPM
  @JsonKey(readValue: _readSamples)
  final List<int> samples;

  /// Constructor
  const PolarExerciseData({required this.interval, required this.samples});

  /// From json
  factory PolarExerciseData.fromJson(Map<String, dynamic> json) =>
      _$PolarExerciseDataFromJson(json);

  /// To json
  Map<String, dynamic> toJson() => _$PolarExerciseDataToJson(this);

  @override
  String toString() {
    return 'PolarExerciseData(interval: $interval, samples: $samples)';
  }
}

Object? _readInterval(Map json, String key) => readPlatformValue(json, {
  TargetPlatform.iOS: 'interval',
  TargetPlatform.android: 'recordingInterval',
});

Object? _readSamples(Map json, String key) => readPlatformValue(json, {
  TargetPlatform.iOS: 'samples',
  TargetPlatform.android: 'hrSamples',
});
