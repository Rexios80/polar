import 'package:json_annotation/json_annotation.dart';
import 'package:polar/polar.dart';
import 'package:polar/src/model/convert.dart';

part 'polar_offline_record_entry.g.dart';

/// A class representing an offline recording entry from a Polar device.
@JsonSerializable()
class PolarOfflineRecordingEntry {
  /// The file path of the recording.
  final String path;

  /// The size of the recording file in bytes.
  final int size;

  /// The date and time when the recording was made.
  @UnixTimeConverter()
  final DateTime date;

  /// The type of data recorded by the Polar device.
  @PolarDataTypeConverter()
  final PolarDataType type;

  /// Constructs a [PolarOfflineRecordingEntry] with the given parameters.
  PolarOfflineRecordingEntry({
    required this.path,
    required this.size,
    required this.date,
    required this.type,
  });

  /// Creates a new instance from a JSON object.
  factory PolarOfflineRecordingEntry.fromJson(Map<String, dynamic> json) =>
      _$PolarOfflineRecordingEntryFromJson(json);

  /// Converts the instance to a JSON object.
  Map<String, dynamic> toJson() => _$PolarOfflineRecordingEntryToJson(this);
}
