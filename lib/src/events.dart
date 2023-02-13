import 'package:polar/src/model/polar_ble_sdk_feature.dart';

/// The feature is available in this device and it is ready. Called only for
/// the features which are specified in [PolarBleApi] construction.
class PolarSdkFeatureReadyEvent {
  /// Polar device id
  final String identifier;

  /// The [PolarSdkFeature] that is ready
  final PolarSdkFeature feature;

  /// Constructor
  PolarSdkFeatureReadyEvent(this.identifier, this.feature);
}

/// Received DIS info.
class PolarDisInformationEvent {
  /// Polar device id
  final String identifier;

  /// UUID of the sensor
  final String uuid;

  /// firmware version in format major.minor.patch
  final String info;

  /// Constructor
  PolarDisInformationEvent(this.identifier, this.uuid, this.info);
}

/// Battery level received from device.
class PolarBatteryLevelEvent {
  /// Polar device id
  final String identifier;

  /// battery level in precentage 0-100%
  final int level;

  /// Constructor
  PolarBatteryLevelEvent(this.identifier, this.level);
}
