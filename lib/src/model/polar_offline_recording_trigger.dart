import 'package:json_annotation/json_annotation.dart';
import 'package:polar/src/model/polar_device_data_type.dart';
import 'package:polar/src/model/polar_sensor_setting.dart';

part 'polar_offline_recording_trigger.g.dart';

@JsonSerializable(explicitToJson: true)
class PolarOfflineRecordingTrigger {
  final PolarOfflineRecordingTriggerMode triggerMode;
  final Map<PolarDataType, PolarSensorSetting?> triggerFeatures;

  PolarOfflineRecordingTrigger({
    required this.triggerMode,
    required this.triggerFeatures,
  });

  factory PolarOfflineRecordingTrigger.fromJson(Map<String, dynamic> json) =>
      _$PolarOfflineRecordingTriggerFromJson(json);

  Map<String, dynamic> toJson() => _$PolarOfflineRecordingTriggerToJson(this);

  @override
  String toString() {
    return 'PolarOfflineRecordingTrigger(triggerMode: $triggerMode, triggerFeatures: $triggerFeatures)';
  }
}

enum PolarOfflineRecordingTriggerMode {
  @JsonValue(0)
  triggerDisabled,

  @JsonValue(1)
  triggerSystemStart,

  @JsonValue(2)
  triggerExerciseStart,
}
