import 'package:meta/meta.dart';
import 'package:polar/polar.dart';

/// The feature is available in this device and it is ready. Called only for
/// the features which are specified in [PolarBleApi] construction.
///
/// Prefer [Polar.sdkFeaturesReadiness] to wait until all features have been
/// evaluated.
@immutable
class PolarSdkFeatureReadyEvent {
  /// Polar device id
  final String identifier;

  /// The [PolarSdkFeature] that is ready
  final PolarSdkFeature feature;

  /// Constructor
  const PolarSdkFeatureReadyEvent(this.identifier, this.feature);
}

/// All requested features have been evaluated after a device connection.
@immutable
class PolarSdkFeaturesReadinessEvent {
  /// Polar device id
  final String identifier;

  /// Features that are confirmed ready for use on this device
  final Set<PolarSdkFeature> ready;

  /// Features that are not supported by this device
  final Set<PolarSdkFeature> unavailable;

  /// Constructor
  const PolarSdkFeaturesReadinessEvent(
    this.identifier,
    this.ready,
    this.unavailable,
  );
}

/// Received DIS info.
@immutable
class PolarDisInformationEvent {
  /// Polar device id
  final String identifier;

  /// UUID of the sensor
  final String uuid;

  /// firmware version in format major.minor.patch
  final String info;

  /// Constructor
  const PolarDisInformationEvent(this.identifier, this.uuid, this.info);
}

/// Battery level received from device.
@immutable
class PolarBatteryLevelEvent {
  /// Polar device id
  final String identifier;

  /// battery level in precentage 0-100%
  final int level;

  /// Constructor
  const PolarBatteryLevelEvent(this.identifier, this.level);
}

/// battery charging status
@immutable
class PolarBatteryChargingStatusEvent {
  /// Polar device id
  final String identifier;

  /// true if charging
  final PolarChargeState chargingStatus;

  /// Constructor
  const PolarBatteryChargingStatusEvent(this.identifier, this.chargingStatus);
}

/// Polar disconnect event
@immutable
class PolarDeviceDisconnectedEvent {
  /// The polar device info
  final PolarDeviceInfo info;

  /// If this disconnect was caused by a pairing error
  ///
  /// iOS only. See https://github.com/polarofficial/polar-ble-sdk/releases/tag/5.2.0
  final bool pairingError;

  /// Constructor
  const PolarDeviceDisconnectedEvent(this.info, this.pairingError);
}
