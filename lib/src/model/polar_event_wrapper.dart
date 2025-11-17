import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'polar_event_wrapper.g.dart';

/// Wrapper for events received from the native code
@JsonSerializable()
@immutable
class PolarEventWrapper {
  /// The event type
  final PolarEvent event;

  /// The event data
  final dynamic data;

  /// Constructor
  const PolarEventWrapper(this.event, this.data);

  /// From json
  factory PolarEventWrapper.fromJson(Map<String, dynamic> json) =>
      _$PolarEventWrapperFromJson(json);

  /// To json
  Map<String, dynamic> toJson() => _$PolarEventWrapperToJson(this);
}

/// Polar event types
enum PolarEvent {
  /// BLE power state changed
  blePowerStateChanged,

  /// SDK feature ready
  sdkFeatureReady,

  /// Device connected
  deviceConnected,

  /// Device connecting
  deviceConnecting,

  /// Device disconnected
  deviceDisconnected,

  /// DIS information received
  disInformationReceived,

  /// Battery level received
  batteryLevelReceived,

  /// Battery charging status received
  batteryChargingStatusReceived,
}
