import 'package:polar/src/model/device_streaming_feature.dart';
import 'package:polar/src/model/polar_hr_data.dart';

/// feature ready callback
class PolarStreamingFeaturesReadyEvent {
  /// Polar device id
  final String identifier;

  /// List of [DeviceStreamingFeature]s that are ready
  final List<DeviceStreamingFeature> features;

  /// Construct a [PolarStreamingFeaturesReadyEvent] from an [identifier] and [features]
  PolarStreamingFeaturesReadyEvent(this.identifier, this.features);
}

/// Received DIS info.
class PolarDisInformationEvent {
  /// Polar device id
  final String identifier;

  /// UUID of the sensor
  final String uuid;

  /// firmware version in format major.minor.patch
  final String info;

  /// Construct a [PolarDisInformationEvent] from an [identifier], [uuid], and [info]
  PolarDisInformationEvent(this.identifier, this.uuid, this.info);
}

/// Battery level received from device.
class PolarBatteryLevelEvent {
  /// Polar device id
  final String identifier;

  /// battery level in precentage 0-100%
  final int level;

  /// Construct a [PolarBatteryLevelEvent] from an [identifier] and [level]
  PolarBatteryLevelEvent(this.identifier, this.level);
}

/// HR notification received.
class PolarHeartRateEvent {
  /// Polar device id
  final String identifier;

  /// The [PolarHrData] received from the sensor
  final PolarHrData data;

  /// Construct a [PolarHeartRateEvent] from an [identifier] and [data]
  PolarHeartRateEvent(this.identifier, this.data);
}
