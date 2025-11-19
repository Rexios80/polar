import 'package:recase/recase.dart';

/// Features available in Polar BLE SDK library
enum PolarSdkFeature {
  /// Hr feature to receive hr and rr data from Polar or any other BLE device
  /// via standard HR BLE service
  hr,

  /// Device information feature to receive sw information from Polar or any
  /// other BLE device
  deviceInfo,

  /// Feature to receive battery level info from Polar or any other BLE device
  batteryInfo,

  /// Polar sensor streaming feature to stream live online data. For example
  /// hr, ecg, acc, ppg, ppi, etc...
  onlineStreaming,

  /// Polar offline recording feature to record offline data to Polar device
  /// without continuous BLE connection.
  offlineRecording,

  /// H10 exercise recording feature to record exercise data to Polar H10
  /// device without continuous BLE connection.
  h10ExerciseRecording,

  /// Feature to read and set device time in Polar device
  deviceTimeSetup,

  /// In SDK mode the wider range of capabilities are available for the online
  /// stream or offline recoding than in normal operation mode.
  sdkMode,

  /// Feature to enable or disable SDK mode blinking LED animation.
  ledAnimation,

  /// Firmware update for Polar device.
  firmwareUpdate,

  /// Feature to receive activity data from Polar device.
  activityData,

  /// Feature to transfer files to and from Polar device.
  fileTransfer,

  /// Feature to receive HTS data from Polar device.
  hts,

  /// Feature to receive sleep data from Polar device.
  sleepData,

  /// Feature to receive temperature data from Polar device.
  temperatureData;

  static const _prefixFeature = 'FEATURE_';
  static const _prefixFeaturePolar = 'FEATURE_POLAR_';

  String get _platformPrefix => switch (this) {
    hr || deviceInfo || batteryInfo || hts => _prefixFeature,
    _ => _prefixFeaturePolar,
  };

  /// Create a [PolarSdkFeature] from json
  static PolarSdkFeature fromJson(dynamic json) {
    var featureString = (json as String).toUpperCase();

    if (featureString.startsWith(_prefixFeaturePolar)) {
      featureString = featureString.substring(_prefixFeaturePolar.length);
    } else if (featureString.startsWith(_prefixFeature)) {
      featureString = featureString.substring(_prefixFeature.length);
    }

    return values.byName(featureString.camelCase);
  }

  /// Convert a [PolarSdkFeature] to json
  dynamic toJson() {
    return '$_platformPrefix${name.snakeCase.toUpperCase()}';
  }
}
