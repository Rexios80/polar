import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:polar/polar.dart';
import 'package:polar/src/model/polar_event_wrapper.dart';

/// Flutter implementation of the [PolarBleSdk]
class Polar {
  static const _methodChannel = MethodChannel('polar/methods');
  static const _eventChannel = EventChannel('polar/events');
  static const _searchChannel = EventChannel('polar/search');

  static Polar? _instance;

  /// Will request location permission on Android S+ if false
  final bool _bluetoothScanNeverForLocation;

  Polar._(this._bluetoothScanNeverForLocation);

  /// Initialize the Polar API. Returns a singleton.
  ///
  /// DartDocs are copied from the iOS version of the SDK and are only included for reference
  ///
  /// The plugin will request location permission on Android S+ if [bluetoothScanNeverForLocation] is false
  factory Polar({bool bluetoothScanNeverForLocation = true}) =>
      _instance ??= Polar._(bluetoothScanNeverForLocation);

  late final _eventStream = _eventChannel
      .receiveBroadcastStream(identityHashCode(this))
      .map((e) => (e as Map).cast<String, dynamic>())
      .map(PolarEventWrapper.fromJson);

  /// helper to ask ble power state
  Stream<bool> get blePowerState => _eventStream
      .where((e) => e.event == PolarEvent.blePowerStateChanged)
      .map((e) => e.data);

  /// feature ready callback
  Stream<PolarSdkFeatureReadyEvent> get sdkFeatureReady =>
      _eventStream.where((e) => e.event == PolarEvent.sdkFeatureReady).map(
            (e) => PolarSdkFeatureReadyEvent(
              e.data[0],
              PolarSdkFeature.fromJson(e.data[1]),
            ),
          );

  /// Device connection has been established.
  ///
  /// - Parameter identifier: Polar device info
  Stream<PolarDeviceInfo> get deviceConnected => _eventStream
      .where((e) => e.event == PolarEvent.deviceConnected)
      .map((e) => PolarDeviceInfo.fromJson(jsonDecode(e.data)));

  /// Callback when connection attempt is started to device
  ///
  /// - Parameter identifier: Polar device info
  Stream<PolarDeviceInfo> get deviceConnecting => _eventStream
      .where((e) => e.event == PolarEvent.deviceConnecting)
      .map((e) => PolarDeviceInfo.fromJson(jsonDecode(e.data)));

  /// Connection lost to device.
  /// If PolarBleApi#disconnectFromPolarDevice is not called, a new connection attempt is dispatched automatically.
  ///
  /// - Parameter identifier: Polar device info
  Stream<PolarDeviceDisconnectedEvent> get deviceDisconnected =>
      _eventStream.where((e) => e.event == PolarEvent.deviceDisconnected).map(
            (e) => PolarDeviceDisconnectedEvent(
              PolarDeviceInfo.fromJson(jsonDecode(e.data[0])),
              e.data[1],
            ),
          );

  ///  Received DIS info.
  ///
  /// - Parameters:
  ///   - identifier: Polar device id
  ///   - fwVersion: firmware version in format major.minor.patch
  Stream<PolarDisInformationEvent> get disInformation => _eventStream
      .where((e) => e.event == PolarEvent.disInformationReceived)
      .map((e) => PolarDisInformationEvent(e.data[0], e.data[1], e.data[2]));

  /// Battery level received from device.
  ///
  /// - Parameters:
  ///   - identifier: Polar device id
  ///   - batteryLevel: battery level in precentage 0-100%
  Stream<PolarBatteryLevelEvent> get batteryLevel => _eventStream
      .where((e) => e.event == PolarEvent.batteryLevelReceived)
      .map((e) => PolarBatteryLevelEvent(e.data[0], e.data[1]));

  /// Battery charging status received from device.
  Stream<PolarBatteryChargingStatusEvent> get batteryChargingStatus =>
      _eventStream
          .where((e) => e.event == PolarEvent.batteryChargingStatusReceived)
          .map(
            (e) => PolarBatteryChargingStatusEvent(
              e.data[0],
              PolarChargeState.fromJson(e.data[1]),
            ),
          );

  /// Start searching for Polar device(s)
  ///
  /// - Parameter onNext: Invoked once for each device
  /// - Returns: Observable stream
  ///  - onNext: for every new polar device found
  Stream<PolarDeviceInfo> searchForDevice() {
    return _searchChannel.receiveBroadcastStream().map(
          (event) => PolarDeviceInfo.fromJson(jsonDecode(event)),
        );
  }

  /// Request a connection to a Polar device. Invokes `PolarBleApiObservers` polarDeviceConnected.
  /// - Parameter identifier: Polar device id printed on the sensor/device or UUID.
  /// - Throws: InvalidArgument if identifier is invalid polar device id or invalid uuid
  ///
  /// Will request the necessary permissions if [requestPermissions] is true
  Future<void> connectToDevice(
    String identifier, {
    bool requestPermissions = true,
  }) async {
    if (requestPermissions) {
      await this.requestPermissions();
    }

    unawaited(_methodChannel.invokeMethod('connectToDevice', identifier));
  }

  /// Request the necessary permissions on Android
  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidDeviceInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidDeviceInfo.version.sdkInt;

      // If we are on Android M+
      if (sdkInt >= 23) {
        // If we are on an Android version before S or bluetooth scan is used to derive location
        if (sdkInt < 31 || !_bluetoothScanNeverForLocation) {
          await Permission.location.request();
        }
        // If we are on Android S+
        if (sdkInt >= 31) {
          await Permission.bluetoothScan.request();
          await Permission.bluetoothConnect.request();
        }
      }
    }
  }

  /// Disconnect from the current Polar device.
  ///
  /// - Parameter identifier: Polar device id
  /// - Throws: InvalidArgument if identifier is invalid polar device id or invalid uuid
  Future<void> disconnectFromDevice(String identifier) {
    return _methodChannel.invokeMethod('disconnectFromDevice', identifier);
  }

  ///  Get the data types available in this device for online streaming
  ///
  /// - Parameters:
  ///   - identifier: polar device id
  /// - Returns: Single stream
  ///   - success: set of available online streaming data types in this device
  ///   - onError: see `PolarErrors` for possible errors invoked
  Future<Set<PolarDataType>> getAvailableOnlineStreamDataTypes(
    String identifier,
  ) async {
    final response = await _methodChannel.invokeMethod(
      'getAvailableOnlineStreamDataTypes',
      identifier,
    );
    if (response == null) return {};
    return (jsonDecode(response) as List).map(PolarDataType.fromJson).toSet();
  }

  ///  Request the stream settings available in current operation mode. This request shall be used before the stream is started
  ///  to decide currently available settings. The available settings depend on the state of the device. For example, if any stream(s)
  ///  or optical heart rate measurement is already enabled, then the device may limit the offer of possible settings for other stream feature.
  ///  Requires `polarSensorStreaming` feature.
  ///
  /// - Parameters:
  ///   - identifier: polar device id
  ///   - feature: selected feature from`PolarDeviceDataType`
  /// - Returns: Single stream
  ///   - success: once after settings received from device
  ///   - onError: see `PolarErrors` for possible errors invoked
  Future<PolarSensorSetting> requestStreamSettings(
    String identifier,
    PolarDataType feature,
  ) async {
    final response = await _methodChannel.invokeMethod(
      'requestStreamSettings',
      [identifier, feature.toJson()],
    );
    return PolarSensorSetting.fromJson(jsonDecode(response));
  }

  Stream<Map<String, dynamic>> _startStreaming(
    PolarDataType feature,
    String identifier, {
    PolarSensorSetting? settings,
  }) async* {
    assert(settings == null || settings.isSelection);

    final channelName = 'polar/streaming/$identifier/${feature.name}';

    await _methodChannel.invokeMethod('createStreamingChannel', [
      channelName,
      identifier,
      feature.toJson(),
    ]);

    if (settings == null && feature.supportsStreamSettings) {
      final availableSettings = await requestStreamSettings(
        identifier,
        feature,
      );
      settings = availableSettings.maxSettings();
    }

    yield* EventChannel(channelName)
        .receiveBroadcastStream(jsonEncode(settings))
        .cast<String>()
        .map(jsonDecode)
        .cast<Map<String, dynamic>>();
  }

  /// Start heart rate stream. Heart rate stream is stopped if the connection is closed,
  /// error occurs or stream is disposed.
  ///
  /// - Parameters:
  ///   - identifier: Polar device id or device address
  /// - Returns: Observable stream
  ///   - onNext: for every air packet received. see `PolarHrData`
  ///   - onError: see `PolarErrors` for possible errors invoked
  Stream<PolarHrData> startHrStreaming(String identifier) {
    return _startStreaming(PolarDataType.hr, identifier)
        .map(PolarHrData.fromJson);
  }

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
  }) {
    return _startStreaming(
      PolarDataType.ecg,
      identifier,
      settings: settings,
    ).map(PolarEcgData.fromJson);
  }

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
  }) {
    return _startStreaming(
      PolarDataType.acc,
      identifier,
      settings: settings,
    ).map(PolarAccData.fromJson);
  }

  /// Start Gyro stream. Gyro stream is stopped if the connection is closed, error occurs during start or stream is disposed.
  ///
  /// - Parameters:
  ///   - identifier: Polar device id or device address
  ///   - settings: selected settings to start the stream
  Stream<PolarGyroData> startGyroStreaming(
    String identifier, {
    PolarSensorSetting? settings,
  }) {
    return _startStreaming(
      PolarDataType.gyro,
      identifier,
      settings: settings,
    ).map(PolarGyroData.fromJson);
  }

  /// Start magnetometer stream. Magnetometer stream is stopped if the connection is closed, error occurs or stream is disposed.
  ///
  /// - Parameters:
  ///   - identifier: Polar device id or device address
  ///   - settings: selected settings to start the stream
  Stream<PolarMagnetometerData> startMagnetometerStreaming(
    String identifier, {
    PolarSensorSetting? settings,
  }) {
    return _startStreaming(
      PolarDataType.magnetometer,
      identifier,
      settings: settings,
    ).map(PolarMagnetometerData.fromJson);
  }

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
  }) {
    return _startStreaming(
      PolarDataType.ppg,
      identifier,
      settings: settings,
    ).map(PolarPpgData.fromJson);
  }

  /// Start PPI (Pulse to Pulse interval) stream.
  /// PPI stream is stopped if the connection is closed, error occurs or stream is disposed.
  /// Notice that there is a delay before PPI data stream starts.
  ///
  /// - Parameters:
  ///   - identifier: Polar device id or device address
  /// - Returns: Observable stream
  ///   - onNext: for every air packet received. see `PolarPpiData`
  ///   - onError: see `PolarErrors` for possible errors invoked
  Stream<PolarPpiData> startPpiStreaming(String identifier) {
    return _startStreaming(PolarDataType.ppi, identifier)
        .map(PolarPpiData.fromJson);
  }

  /// Start temperature stream. Temperature stream is stopped if the connection is closed,
  /// error occurs or stream is disposed.
  ///
  /// - Parameters:
  ///   - identifier: Polar device id or device address
  ///   - settings: selected settings to start the stream
  /// - Returns: Observable stream
  ///   - onNext: for every air packet received. see `PolarTemperatureData`
  ///   - onError: see `PolarErrors` for possible errors invoked
  Stream<PolarTemperatureData> startTemperatureStreaming(
    String identifier, {
    PolarSensorSetting? settings,
  }) {
    return _startStreaming(
      PolarDataType.temperature,
      identifier,
      settings: settings,
    ).map(PolarTemperatureData.fromJson);
  }

  /// Start pressure stream. Pressure stream is stopped if the connection is closed,
  /// error occurs or stream is disposed.
  ///
  /// - Parameters:
  ///   - identifier: Polar device id or device address
  ///   - settings: selected settings to start the stream
  /// - Returns: Observable stream
  ///   - onNext: for every air packet received. see `PolarPressureData`
  ///   - onError: see `PolarErrors` for possible errors invoked
  Stream<PolarPressureData> startPressureStreaming(
    String identifier, {
    PolarSensorSetting? settings,
  }) {
    return _startStreaming(
      PolarDataType.pressure,
      identifier,
      settings: settings,
    ).map(PolarPressureData.fromJson);
  }

  /// Start skin temperature stream. Skin temperature stream is stopped if the connection is closed,
  /// error occurs or stream is disposed.
  ///
  /// - Parameters:
  ///   - identifier: Polar device id or device address
  ///   - settings: selected settings to start the stream
  /// - Returns: Observable stream
  ///   - onNext: for every air packet received. see `PolarSkinTemperatureData`
  ///   - onError: see `PolarErrors` for possible errors invoked
  Stream<PolarTemperatureData> startSkinTemperatureStreaming(
    String identifier, {
    PolarSensorSetting? settings,
  }) {
    return _startStreaming(
      PolarDataType.skinTemperature,
      identifier,
      settings: settings,
    ).map(PolarTemperatureData.fromJson);
  }

  /// Start location stream. Location stream is stopped if the connection is closed,
  /// error occurs or stream is disposed. This is not supported on IOS.
  ///
  /// - Parameters:
  ///   - identifier: Polar device id or device address
  ///   - settings: selected settings to start the stream
  /// - Returns: Observable stream
  ///   - onNext: for every air packet received. see `PolarLocationData`
  ///   - onError: see `PolarErrors` for possible errors invoked
  Stream<PolarLocationData> startLocationStreaming(
    String identifier, {
    PolarSensorSetting? settings,
  }) {
    return _startStreaming(
      PolarDataType.location,
      identifier,
      settings: settings,
    ).map(PolarLocationData.fromJson);
  }

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
  }) {
    return _methodChannel.invokeMethod(
      'startRecording',
      [identifier, exerciseId, interval.toJson(), sampleType.toJson()],
    );
  }

  /// Request stop for current recording. Supported only by Polar H10. Requires `polarFileTransfer` feature.
  ///
  /// - Parameters:
  ///   - identifier: Polar device id or UUID
  /// - Returns: Completable stream
  ///   - success: recording stopped
  ///   - onError: see `PolarErrors` for possible errors invoked
  Future<void> stopRecording(String identifier) {
    return _methodChannel.invokeMethod('stopRecording', identifier);
  }

  /// Request current recording status. Supported only by Polar H10. Requires `polarFileTransfer` feature.
  ///
  /// - Parameters:
  ///   - identifier: Polar device id
  /// - Returns: Single stream
  ///   - success: see `PolarRecordingStatus`
  ///   - onError: see `PolarErrors` for possible errors invoked
  Future<PolarRecordingStatus> requestRecordingStatus(String identifier) async {
    final result = await _methodChannel.invokeListMethod(
      'requestRecordingStatus',
      identifier,
    );

    return PolarRecordingStatus(ongoing: result![0], entryId: result[1]);
  }

  /// Api for fetching stored exercises list from Polar H10 device. Requires `polarFileTransfer` feature. This API is working for Polar OH1 and Polar Verity Sense devices too, however in those devices recording of exercise requires that sensor is registered to Polar Flow account.
  ///
  /// - Parameters:
  ///   - identifier: Polar device id or device address
  /// - Returns: Observable stream
  ///   - onNext: see `PolarExerciseEntry`
  ///   - onError: see `PolarErrors` for possible errors invoked
  Future<List<PolarExerciseEntry>> listExercises(String identifier) async {
    final result =
        await _methodChannel.invokeListMethod('listExercises', identifier);
    if (result == null) {
      return [];
    }
    return result
        .cast<String>()
        .map((e) => PolarExerciseEntry.fromJson(jsonDecode(e)))
        .toList();
  }

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
  ) async {
    final result = await _methodChannel
        .invokeMethod('fetchExercise', [identifier, jsonEncode(entry)]);
    return PolarExerciseData.fromJson(jsonDecode(result));
  }

  /// Api for removing single exercise from Polar H10 device. Requires `polarFileTransfer` feature. This API is working for Polar OH1 and Polar Verity Sense devices too, however in those devices recording of exercise requires that sensor is registered to Polar Flow account.
  ///
  /// - Parameters:
  ///   - identifier: Polar device id or device address
  ///   - entry: single exercise entry to be removed
  /// - Returns: Completable stream
  ///   - complete: entry successfully removed
  ///   - onError: see `PolarErrors` for possible errors invoked
  Future<void> removeExercise(String identifier, PolarExerciseEntry entry) {
    return _methodChannel
        .invokeMethod('removeExercise', [identifier, jsonEncode(entry)]);
  }

  /// Set [LedConfig] to enable or disable blinking LEDs (Verity Sense 2.2.1+).
  ///
  /// - Parameters:
  ///   - identifier: polar device id or UUID
  ///   - ledConfig: to enable or disable LEDs blinking
  /// - Returns: Completable stream
  ///   - success: when enable or disable sent to device
  ///   - onError: see `PolarErrors` for possible errors invoked
  Future<void> setLedConfig(String identifier, LedConfig config) {
    return _methodChannel
        .invokeMethod('setLedConfig', [identifier, jsonEncode(config)]);
  }

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
  ) {
    return _methodChannel.invokeMethod(
      'doFactoryReset',
      [identifier, preservePairingInformation],
    );
  }

  ///  Enables SDK mode.
  Future<void> enableSdkMode(String identifier) {
    return _methodChannel.invokeMethod('enableSdkMode', identifier);
  }

  /// Disables SDK mode.
  Future<void> disableSdkMode(String identifier) {
    return _methodChannel.invokeMethod('disableSdkMode', identifier);
  }

  /// Check if SDK mode currently enabled.
  ///
  /// Note, SDK status check is supported by VeritySense starting from firmware 2.1.0
  Future<bool> isSdkModeEnabled(String identifier) async {
    final result =
        await _methodChannel.invokeMethod<bool>('isSdkModeEnabled', identifier);
    return result!;
  }
}
