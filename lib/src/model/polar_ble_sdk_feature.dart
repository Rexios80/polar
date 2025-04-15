import 'dart:io';

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
  featurePolarFirmwareUpdate,

  /// Feature to receive activity data from Polar device.
  featurePolarActivityData,

  /// Feature to transfer files to and from Polar device.
  featurePolarFileTransfer,

  /// Feature to receive HTS data from Polar device.
  featureHts,

  /// Feature to receive sleep data from Polar device.
  featurePolarSleepData,

  /// Feature to receive temperature data from Polar device.
  featurePolarTemperatureData;

  static const _featureStringMap = {
    hr: 'FEATURE_HR',
    deviceInfo: 'FEATURE_DEVICE_INFO',
    batteryInfo: 'FEATURE_BATTERY_INFO',
    onlineStreaming: 'FEATURE_POLAR_ONLINE_STREAMING',
    offlineRecording: 'FEATURE_POLAR_OFFLINE_RECORDING',
    h10ExerciseRecording: 'FEATURE_POLAR_H10_EXERCISE_RECORDING',
    deviceTimeSetup: 'FEATURE_POLAR_DEVICE_TIME_SETUP',
    sdkMode: 'FEATURE_POLAR_SDK_MODE',
    ledAnimation: 'FEATURE_POLAR_LED_ANIMATION',
    featurePolarFirmwareUpdate: 'FEATURE_POLAR_FIRMWARE_UPDATE',
    featurePolarActivityData: 'FEATURE_POLAR_ACTIVITY_DATA',
    featurePolarFileTransfer: 'FEATURE_POLAR_FILE_TRANSFER',
    featureHts: 'FEATURE_HTS',
    featurePolarSleepData: 'FEATURE_POLAR_SLEEP_DATA',
    featurePolarTemperatureData: 'FEATURE_POLAR_TEMPERATURE_DATA',
  };

  static final _stringFeatureMap =
      _featureStringMap.map((k, v) => MapEntry(v, k));

  /// Create a [PolarSdkFeature] from json
  static PolarSdkFeature fromJson(dynamic json) {
    if (Platform.isIOS) {
      return PolarSdkFeature.values[json as int];
    } else {
      // This is android
      return _stringFeatureMap[json as String]!;
    }
  }

  /// Convert a [PolarSdkFeature] to json
  dynamic toJson() {
    if (Platform.isIOS) {
      return PolarSdkFeature.values.indexOf(this);
    } else {
      // This is Android
      return _featureStringMap[this]!;
    }
  }
}
