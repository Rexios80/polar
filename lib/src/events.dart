import 'package:polar/src/model/polar_ble_sdk_feature.dart';

/// The feature is available in this device and it is ready.
/// Called only for the features which are specified in [PolarBleApi]
/// construction.
class PolarBlsSdkFeatureReadyEvent {
  /// Polar device id
  final String identifier;

  /// List of [PolarBleSdkFeature]s that are ready
  final List<PolarBleSdkFeature> features;

  /// Construct a [PolarBlsSdkFeatureReadyEvent] from an [identifier] and [features]
  PolarBlsSdkFeatureReadyEvent(this.identifier, this.features);
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
