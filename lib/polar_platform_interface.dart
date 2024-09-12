import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:polar/polar.dart';

import 'package:polar/polar_method_channel.dart';

/// An abstract class that defines the interface for the Polar SDK platform.
/// This class extends [PlatformInterface].
abstract class PolarSdkPlatform extends PlatformInterface {
  /// Constructs a [PolarSdkPlatform] instance.
  ///
  /// Takes an optional boolean parameter [_bluetoothScanNeverForLocation] which defaults to `true`.
  /// If set to `true`, the SDK will not request location permission on Android S+ during Bluetooth scanning.
  PolarSdkPlatform([this._bluetoothScanNeverForLocation = true])
      : super(token: _token);

  /// Factory constructor to initialize a [PolarSdkPlatform] instance.
  ///
  /// Takes an optional boolean parameter [bluetoothScanNeverForLocation] which defaults to `true`.
  /// If the instance is not already created, it initializes a new [MethodChannelPolarSdk] instance.
  factory PolarSdkPlatform.init([bool bluetoothScanNeverForLocation = true]) =>
      MethodChannelPolarSdk(bluetoothScanNeverForLocation);

  static final Object _token = Object();

  /// Will request location permission on Android S+ if false
  final bool _bluetoothScanNeverForLocation;

  /// Returns the current value of `_bluetoothScanNeverForLocation`.
  ///
  /// If `true`, the SDK will not request location permission on Android S+ during Bluetooth scanning.
  bool get bluetoothScanNeverForLocation => _bluetoothScanNeverForLocation;

  /// Helper method to get the BLE power state.
  ///
  /// Returns a Stream<bool> indicating the power state.
  Stream<bool> get blePowerState;

  /// Callback when a feature is ready.
  ///
  /// Returns a Stream<PolarSdkFeatureReadyEvent>.
  Stream<PolarSdkFeatureReadyEvent> get sdkFeatureReady;

  /// Callback when a device connection has been established.
  ///
  /// - Parameter identifier: Polar device info
  /// Returns a Stream<PolarDeviceInfo>.
  Stream<PolarDeviceInfo> get deviceConnected;

  /// Callback when a connection attempt is started to a device.
  ///
  /// - Parameter identifier: Polar device info
  /// Returns a Stream<PolarDeviceInfo>.
  Stream<PolarDeviceInfo> get deviceConnecting;

  /// Callback when a connection is lost to a device.
  /// If PolarBleApi#disconnectFromPolarDevice is not called, a new connection attempt is dispatched automatically.
  ///
  /// - Parameter identifier: Polar device info
  /// Returns a Stream<PolarDeviceDisconnectedEvent>.
  Stream<PolarDeviceDisconnectedEvent> get deviceDisconnected;

  /// Callback when DIS info is received.
  ///
  /// - Parameters:
  ///   - identifier: Polar device id
  ///   - fwVersion: firmware version in format major.minor.patch
  /// Returns a Stream<PolarDisInformationEvent>.
  Stream<PolarDisInformationEvent> get disInformation;

  /// Callback when battery level is received from a device.
  ///
  /// - Parameters:
  ///   - identifier: Polar device id
  ///   - batteryLevel: battery level in percentage 0-100%
  /// Returns a Stream<PolarBatteryLevelEvent>.
  Stream<PolarBatteryLevelEvent> get batteryLevel;

  /// Start searching for Polar device(s)
  ///
  /// - Returns: Stream<PolarDeviceInfo> for every new polar device found
  Stream<PolarDeviceInfo> searchForDevice();

  /// Request a connection to a Polar device. Invokes `PolarBleApiObservers` polarDeviceConnected.
  /// - Parameter identifier: Polar device id printed on the sensor/device or UUID.
  /// - Throws: InvalidArgument if identifier is invalid polar device id or invalid uuid
  ///
  /// Will request the necessary permissions if [requestPermissions] is true
  Future<void> connectToDevice(
    String identifier, {
    bool requestPermissions = true,
  });

  /// Request the necessary permissions on Android
  Future<void> requestPermissions();

  /// Disconnect from the current Polar device.
  ///
  /// - Parameter identifier: Polar device id
  /// - Throws: InvalidArgument if identifier is invalid polar device id or invalid uuid
  Future<void> disconnectFromDevice(String identifier);

  /// Android Only
  /// Shutdown the Polar SDK
  ///
  /// - Throws: If SDK is already shutdown/not started
  Future<void> shutdown();

  /// Initializes the PolarSDK
  Future<void> init();

  ///  Get the data types available in this device for online streaming
  ///
  /// - Parameter identifier: polar device id
  /// - Returns: Future<Set<PolarDataType>> of available online streaming data types in this device
  Future<Set<PolarDataType>> getAvailableOnlineStreamDataTypes(
    String identifier,
  );

  ///  Request the stream settings available in current operation mode. This request shall be used before the stream is started
  ///  to decide currently available settings. The available settings depend on the state of the device. For example, if any stream(s)
  ///  or optical heart rate measurement is already enabled, then the device may limit the offer of possible settings for other stream feature.
  ///  Requires `polarSensorStreaming` feature.
  ///
  /// - Parameters:
  ///   - identifier: polar device id
  ///   - feature: selected feature from`PolarDeviceDataType`
  /// - Returns: Future<PolarSensorSetting> once after settings received from device
  Future<PolarSensorSetting> requestStreamSettings(
    String identifier,
    PolarDataType feature,
  );

  /// Start heart rate stream. Heart rate stream is stopped if the connection is closed,
  /// error occurs or stream is disposed.
  ///
  /// - Parameters:
  ///   - identifier: Polar device id or device address
  /// - Returns: Observable stream
  ///   - onNext: for every air packet received. see `PolarHrData`
  ///   - onError: see `PolarErrors` for possible errors invoked
  Stream<PolarHrData> startHrStreaming(String identifier);

  /// Start the ECG (Electrocardiography) stream. ECG stream is stopped if the connection is closed, error occurs or stream is disposed.
  ///
  /// - Parameters:
  ///   - identifier: Polar device id or device address
  ///   - settings: selected settings to start the stream
  /// - Returns: Observable stream
  ///   - onNext: for every air packet received. see `PolarEcgData`
  ///   - onError: see `PolarErrors` for possible errors invoked
  Stream<PolarEcgData> startEcgStreaming(
    String identifier, {
    PolarSensorSetting? settings,
  });

  ///  Start ACC (Accelerometer) stream. ACC stream is stopped if the connection is closed, error occurs or stream is disposed.
  /// - Parameters:
  ///   - identifier: Polar device id or device address
  ///   - settings: selected settings to start the stream
  /// - Returns: Observable stream
  ///   - onNext: for every air packet received. see `PolarAccData`
  ///   - onError: see `PolarErrors` for possible errors invoked
  Stream<PolarAccData> startAccStreaming(
    String identifier, {
    PolarSensorSetting? settings,
  });

  /// Start Gyro stream. Gyro stream is stopped if the connection is closed, error occurs during start or stream is disposed.
  ///
  /// - Parameters:
  ///   - identifier: Polar device id or device address
  ///   - settings: selected settings to start the stream
  Stream<PolarGyroData> startGyroStreaming(
    String identifier, {
    PolarSensorSetting? settings,
  });

  /// Start magnetometer stream. Magnetometer stream is stopped if the connection is closed, error occurs or stream is disposed.
  ///
  /// - Parameters:
  ///   - identifier: Polar device id or device address
  ///   - settings: selected settings to start the stream
  Stream<PolarMagnetometerData> startMagnetometerStreaming(
    String identifier, {
    PolarSensorSetting? settings,
  });

  /// Start optical sensor PPG (Photoplethysmography) stream. PPG stream is stopped if the connection is closed, error occurs or stream is disposed.
  ///
  /// - Parameters:
  ///   - identifier: Polar device id or device address
  ///   - settings: selected settings to start the stream
  /// - Returns: Observable stream
  ///   - onNext: for every air packet received. see `PolarPpgData`
  ///   - onError: see `PolarErrors` for possible errors invoked
  Stream<PolarPpgData> startPpgStreaming(
    String identifier, {
    PolarSensorSetting? settings,
  });

  /// Start PPI (Pulse to Pulse interval) stream.
  /// PPI stream is stopped if the connection is closed, error occurs or stream is disposed.
  /// Notice that there is a delay before PPI data stream starts.
  ///
  /// - Parameters:
  ///   - identifier: Polar device id or device address
  /// - Returns: Observable stream
  ///   - onNext: for every air packet received. see `PolarPpiData`
  ///   - onError: see `PolarErrors` for possible errors invoked
  Stream<PolarPpiData> startPpiStreaming(String identifier);

  /// Request start recording. Supported only by Polar H10. Requires `polarFileTransfer` feature.
  ///
  /// - Parameters:
  ///   - identifier: Polar device id or UUID
  ///   - exerciseId: unique identifier for for exercise entry length from 1-64 bytes
  ///   - interval: recording interval to be used. Has no effect if `sampleType` is `SampleType.rr`
  ///   - sampleType: sample type to be used.
  /// - Returns: Completable stream
  ///   - success: recording started
  ///   - onError: see `PolarErrors` for possible errors invoked
  Future<void> startRecording(
    String identifier, {
    required String exerciseId,
    required RecordingInterval interval,
    required SampleType sampleType,
  });

  /// Request stop for current recording. Supported only by Polar H10. Requires `polarFileTransfer` feature.
  ///
  /// - Parameters:
  ///   - identifier: Polar device id or UUID
  /// - Returns: Completable stream
  ///   - success: recording stopped
  ///   - onError: see `PolarErrors` for possible errors invoked
  Future<void> stopRecording(String identifier);

  /// Request current recording status. Supported only by Polar H10. Requires `polarFileTransfer` feature.
  ///
  /// - Parameters:
  ///   - identifier: Polar device id
  /// - Returns: Single stream
  ///   - success: see `PolarRecordingStatus`
  ///   - onError: see `PolarErrors` for possible errors invoked
  Future<PolarRecordingStatus> requestRecordingStatus(String identifier);

  /// Api for fetching stored exercises list from Polar H10 device. Requires `polarFileTransfer` feature. This API is working for Polar OH1 and Polar Verity Sense devices too, however in those devices recording of exercise requires that sensor is registered to Polar Flow account.
  ///
  /// - Parameters:
  ///   - identifier: Polar device id or device address
  /// - Returns: Observable stream
  ///   - onNext: see `PolarExerciseEntry`
  ///   - onError: see `PolarErrors` for possible errors invoked
  Future<List<PolarExerciseEntry>> listExercises(String identifier);

  /// Api for fetching a single exercise from Polar H10 device. Requires `polarFileTransfer` feature. This API is working for Polar OH1 and Polar Verity Sense devices too, however in those devices recording of exercise requires that sensor is registered to Polar Flow account.
  ///
  /// - Parameters:
  ///   - identifier: Polar device id or device address
  ///   - entry: single exercise entry to be fetched
  /// - Returns: Single stream
  ///   - success: invoked after exercise data has been fetched from the device. see `PolarExerciseEntry`
  ///   - onError: see `PolarErrors` for possible errors invoked
  Future<PolarExerciseData> fetchExercise(
    String identifier,
    PolarExerciseEntry entry,
  );

  /// Api for removing single exercise from Polar H10 device. Requires `polarFileTransfer` feature. This API is working for Polar OH1 and Polar Verity Sense devices too, however in those devices recording of exercise requires that sensor is registered to Polar Flow account.
  ///
  /// - Parameters:
  ///   - identifier: Polar device id or device address
  ///   - entry: single exercise entry to be removed
  /// - Returns: Completable stream
  ///   - complete: entry successfully removed
  ///   - onError: see `PolarErrors` for possible errors invoked
  Future<void> removeExercise(String identifier, PolarExerciseEntry entry);

  /// Set [LedConfig] to enable or disable blinking LEDs (Verity Sense 2.2.1+).
  ///
  /// - Parameters:
  ///   - identifier: polar device id or UUID
  ///   - ledConfig: to enable or disable LEDs blinking
  /// - Returns: Completable stream
  ///   - success: when enable or disable sent to device
  ///   - onError: see `PolarErrors` for possible errors invoked
  Future<void> setLedConfig(String identifier, LedConfig config);

  /// Perform factory reset to given device.
  ///
  /// - Parameters:
  ///   - identifier: polar device id or UUID
  ///   - preservePairingInformation: preserve pairing information during factory reset
  /// - Returns: Completable stream
  ///   - success: when factory reset notification sent to device
  ///   - onError: see `PolarErrors` for possible errors invoked
  Future<void> doFactoryReset(
    String identifier,
    bool preservePairingInformation,
  );

  ///  Enables SDK mode.
  Future<void> enableSdkMode(String identifier);

  /// Disables SDK mode.
  Future<void> disableSdkMode(String identifier);

  /// Check if SDK mode currently enabled.
  ///
  /// Note, SDK status check is supported by VeritySense starting from firmware 2.1.0
  Future<bool> isSdkModeEnabled(String identifier);
}
