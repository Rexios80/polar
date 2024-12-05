import 'package:json_annotation/json_annotation.dart';
import 'package:polar/src/model/polar_device_data_type.dart';
import 'package:polar/src/model/polar_sensor_setting.dart';

part 'polar_offline_recording_trigger.g.dart';

/// A class representing an offline recording trigger for a Polar device.
@JsonSerializable(explicitToJson: true)
class PolarOfflineRecordingTrigger {
  /// The mode of the offline recording trigger (e.g., system start, exercise start).
  final PolarOfflineRecordingTriggerMode triggerMode;

  /// A map of the features enabled for the trigger, keyed by the device data type.
  /// The map may contain settings for various device types (e.g., HR, PPI, etc.).
  final Map<PolarDataType, PolarSensorSetting?> triggerFeatures;

  /// Constructs a [PolarOfflineRecordingTrigger] with the specified trigger mode and features.
  ///
  /// [triggerMode] is the mode of the trigger.
  /// [triggerFeatures] is a map of PolarDeviceDataType to PolarSensorSetting containing enabled features for the trigger.
  PolarOfflineRecordingTrigger({
    required this.triggerMode,
    required this.triggerFeatures,
  });

  /// Creates a new [PolarOfflineRecordingTrigger] instance from a JSON object.
  ///
  /// [json] is the JSON object to be deserialized.
  factory PolarOfflineRecordingTrigger.fromJson(Map<String, dynamic> json) =>
      _$PolarOfflineRecordingTriggerFromJson(json);

  /// Converts the current instance into a JSON object.
  ///
  /// Returns a JSON object representing the current [PolarOfflineRecordingTrigger] instance.
  Map<String, dynamic> toJson() => _$PolarOfflineRecordingTriggerToJson(this);

  @override
  String toString() {
    return 'PolarOfflineRecordingTrigger(triggerMode: $triggerMode, triggerFeatures: $triggerFeatures)';
  }
}

/// Enum representing the different modes of the offline recording trigger.
/// The trigger mode defines when the offline recording should be activated.
enum PolarOfflineRecordingTriggerMode {
  /// The trigger is disabled.
  @JsonValue(0)
  triggerDisabled,

  /// The trigger is activated at system start.
  @JsonValue(1)
  triggerSystemStart,

  /// The trigger is activated when exercise starts.
  @JsonValue(2)
  triggerExerciseStart,
}
