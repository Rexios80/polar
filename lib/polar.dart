import 'package:polar/model/polar_ble_sdk_feature.dart';
import 'package:polar/model/polar_device_info.dart';
import 'package:polar/polar_method_channel.dart';

export 'model/led_config.dart';
export 'model/polar_ble_sdk_feature.dart';
export 'model/polar_device_data_type.dart';
export 'model/ppg_data_type.dart';
export 'model/polar_device_info.dart';
export 'model/polar_recording.dart';
export 'model/polar_sensor_setting.dart';
export 'model/polar_streaming.dart';

/// Entry class for the Polar SDK.
class Polar extends MethodChannelPolarSdk {
  /// Constructor for the Polar SDK.
  /// 
  /// [bluetoothScanNeverForLocation] is a boolean that is used to determine if the
  /// bluetooth scan should be started with the location permission.
  Polar({bluetoothScanNeverForLocation = true})
      : super(bluetoothScanNeverForLocation);
}

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

/// Polar disconnect event
class PolarDeviceDisconnectedEvent {
  /// The polar device info
  final PolarDeviceInfo info;

  /// If this disconnect was caused by a pairing error
  ///
  /// iOS only. See https://github.com/polarofficial/polar-ble-sdk/releases/tag/5.2.0
  final bool pairingError;

  /// Constructor
  PolarDeviceDisconnectedEvent(this.info, this.pairingError);
}
