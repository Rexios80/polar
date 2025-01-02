import 'package:json_annotation/json_annotation.dart';
import 'package:polar/polar.dart';
import 'package:polar/src/model/convert.dart';

part 'polar_offline_recording_entry.g.dart';

/// Polar Offline Recording Entry
@JsonSerializable()
class PolarOfflineRecordingEntry {
  /// Recording entry path in device
  final String path;

  /// Recording size in bytes
  final int size;

  /// The date and time of the recording entry, i.e., the moment recording is started
  @UnixTimeConverter()
  final DateTime date;

  /// Data type of the recording
  @JsonKey(fromJson: PolarDataType.fromJson, toJson: _polarDataTypeToJson)
  final PolarDataType type;

  /// Constructor
  PolarOfflineRecordingEntry({
    required this.path,
    required this.size,
    required this.date,
    required this.type,
  });

  /// From json
  factory PolarOfflineRecordingEntry.fromJson(Map<String, dynamic> json) =>
      _$PolarOfflineRecordingEntryFromJson(json);

  /// To json
  Map<String, dynamic> toJson() => _$PolarOfflineRecordingEntryToJson(this);

  @override
  String toString() {
    return 'PolarOfflineRecordingEntry(path: $path, size: $size, date: $date, type: $type)';
  }
}

/// Helper function for PolarDataType serialization
dynamic _polarDataTypeToJson(PolarDataType type) => type.toJson();
