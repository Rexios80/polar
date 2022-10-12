import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:polar/polar.dart';

/// Flutter implementation of the [PolarBleSdk]
class Polar {
  static const _channel = MethodChannel('polar');
  static const _searchChannel = EventChannel('polar/search');
  static const _streamingChannel = EventChannel('polar/streaming');

  // Other data
  final _blePowerStateStreamController = StreamController<bool>.broadcast();
  final _deviceConnectedStreamController =
      StreamController<PolarDeviceInfo>.broadcast();
  final _deviceConnectingStreamController =
      StreamController<PolarDeviceInfo>.broadcast();
  final _deviceDisconnectedStreamController =
      StreamController<PolarDeviceInfo>.broadcast();
  final _streamingFeaturesReadyStreamController =
      StreamController<PolarStreamingFeaturesReadyEvent>.broadcast();
  final _sdkModeFeatureAvailableStreamController =
      StreamController<String>.broadcast();
  final _hrFeatureReadyStreamController = StreamController<String>.broadcast();
  final _disInformationStreamController =
      StreamController<PolarDisInformationEvent>.broadcast();
  final _batteryLevelStreamController =
      StreamController<PolarBatteryLevelEvent>.broadcast();
  final _heartRateStreamController =
      StreamController<PolarHeartRateEvent>.broadcast();
  final _ftpFeatureReadyStreamController = StreamController<String>.broadcast();

  /// helper to ask ble power state
  Stream<bool> get blePowerStateStream => _blePowerStateStreamController.stream;

  /// Device connection has been established.
  ///
  /// - Parameter identifier: Polar device info
  Stream<PolarDeviceInfo> get deviceConnectedStream =>
      _deviceConnectedStreamController.stream;

  /// Callback when connection attempt is started to device
  ///
  /// - Parameter identifier: Polar device info
  Stream<PolarDeviceInfo> get deviceConnectingStream =>
      _deviceConnectingStreamController.stream;

  /// Connection lost to device.
  /// If PolarBleApi#disconnectFromPolarDevice is not called, a new connection attempt is dispatched automatically.
  ///
  /// - Parameter identifier: Polar device info
  Stream<PolarDeviceInfo> get deviceDisconnectedStream =>
      _deviceDisconnectedStreamController.stream;

  /// feature ready callback
  Stream<PolarStreamingFeaturesReadyEvent> get streamingFeaturesReadyStream =>
      _streamingFeaturesReadyStreamController.stream;

  /// sdk mode feature available in this device and ready for usage callback
  Stream<String> get sdkModeFeatureAvailableStream =>
      _sdkModeFeatureAvailableStreamController.stream;

  /// Device HR feature is ready. HR transmission is starting in a short while.
  ///
  /// - Parameter identifier: Polar device id
  Stream<String> get hrFeatureReadyStream =>
      _hrFeatureReadyStreamController.stream;

  ///  Received DIS info.
  ///
  /// - Parameters:
  ///   - identifier: Polar device id
  ///   - fwVersion: firmware version in format major.minor.patch
  Stream<PolarDisInformationEvent> get disInformationStream =>
      _disInformationStreamController.stream;

  /// Battery level received from device.
  ///
  /// - Parameters:
  ///   - identifier: Polar device id
  ///   - batteryLevel: battery level in precentage 0-100%
  Stream<PolarBatteryLevelEvent> get batteryLevelStream =>
      _batteryLevelStreamController.stream;

  /// HR notification received. Notice when using OH1 and PPI stream is started this callback will produce 0 hr.
  ///
  /// - Parameters:
  ///   - identifier: Polar device id
  Stream<PolarHeartRateEvent> get heartRateStream =>
      _heartRateStreamController.stream;

  /// Device file transfer protocol is ready.
  /// Notice all file transfer operations are preferred to be done at beginning of the connection
  ///
  /// - Parameter identifier: polar device id
  Stream<String> get ftpFeatureReadyStream =>
      _ftpFeatureReadyStreamController.stream;

  /// Will request location permission on Android S+ if false
  final bool bluetoothScanNeverForLocation;

  /// Initialize the Polar API
  ///
  /// DartDocs are copied from the iOS version of the SDK and are only included for reference
  ///
  /// The plugin will request location permission on Android S+ if [bluetoothScanNeverForLocation] is false
  Polar({this.bluetoothScanNeverForLocation = true}) {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'blePowerStateChanged':
        _blePowerStateStreamController.add(call.arguments);
        return;
      case 'deviceConnected':
        _deviceConnectedStreamController
            .add(PolarDeviceInfo.fromJson(jsonDecode(call.arguments)));
        return;
      case 'deviceConnecting':
        _deviceConnectingStreamController
            .add(PolarDeviceInfo.fromJson(jsonDecode(call.arguments)));
        return;
      case 'deviceDisconnected':
        _deviceDisconnectedStreamController
            .add(PolarDeviceInfo.fromJson(jsonDecode(call.arguments)));
        return;
      case 'streamingFeaturesReady':
        _streamingFeaturesReadyStreamController.add(
          PolarStreamingFeaturesReadyEvent(
            call.arguments[0],
            (jsonDecode(call.arguments[1]) as List)
                .map((e) => DeviceStreamingFeature.fromJson(e))
                .toList(),
          ),
        );
        return;
      case 'sdkModeFeatureAvailable':
        _sdkModeFeatureAvailableStreamController.add(call.arguments);
        return;
      case 'hrFeatureReady':
        _hrFeatureReadyStreamController.add(call.arguments);
        return;
      case 'disInformationReceived':
        _disInformationStreamController.add(
          PolarDisInformationEvent(
            call.arguments[0],
            call.arguments[1],
            call.arguments[2],
          ),
        );
        return;
      case 'batteryLevelReceived':
        _batteryLevelStreamController.add(
          PolarBatteryLevelEvent(
            call.arguments[0],
            call.arguments[1],
          ),
        );
        return;
      case 'hrNotificationReceived':
        _heartRateStreamController.add(
          PolarHeartRateEvent(
            call.arguments[0],
            PolarHrData.fromJson(jsonDecode(call.arguments[1])),
          ),
        );
        return;
      case 'polarFtpFeatureReady':
        _ftpFeatureReadyStreamController.add(call.arguments);
        return;
      default:
        throw UnimplementedError(call.method);
    }
  }

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

    unawaited(_channel.invokeMethod('connectToDevice', identifier));
  }

  /// Request the necessary permissions on Android
  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidDeviceInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidDeviceInfo.version.sdkInt;

      // If we are on Android M+
      if (sdkInt != null && sdkInt >= 23) {
        // If we are on an Android version before S or bluetooth scan is used to derive location
        if (sdkInt < 31 || !bluetoothScanNeverForLocation) {
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
    return _channel.invokeMethod('disconnectFromDevice', identifier);
  }

  ///  Request the stream settings available in current operation mode. This request shall be used before the stream is started
  ///  to decide currently available settings. The available settings depend on the state of the device. For example, if any stream(s)
  ///  or optical heart rate measurement is already enabled, then the device may limit the offer of possible settings for other stream feature.
  ///  Requires `polarSensorStreaming` feature.
  ///
  /// - Parameters:
  ///   - identifier: polar device id
  ///   - feature: selected feature from`DeviceStreamingFeature`
  /// - Returns: Single stream
  ///   - success: once after settings received from device
  ///   - onError: see `PolarErrors` for possible errors invoked
  Future<PolarSensorSetting> requestStreamSettings(
    String identifier,
    DeviceStreamingFeature feature,
  ) async {
    final response = await _channel.invokeMethod(
      'requestStreamSettings',
      [identifier, feature.toJson()],
    );
    return PolarSensorSetting.fromJson(jsonDecode(response));
  }

  Stream _startStreaming(
    DeviceStreamingFeature feature,
    String identifier, {
    PolarSensorSetting? settings,
  }) async* {
    if (feature != DeviceStreamingFeature.ppi) {
      settings ??= await requestStreamSettings(
        identifier,
        feature,
      );
    }

    yield* _streamingChannel.receiveBroadcastStream(
      [feature.toJson(), identifier, jsonEncode(settings)],
    );
  }

  /// Start the ECG (Electrocardiography) stream. ECG stream is stopped if the connection is closed, error occurs or stream is disposed.
  /// Requires `polarSensorStreaming` feature. Before starting the stream it is recommended to query the available settings using `requestStreamSettings`
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
      DeviceStreamingFeature.ecg,
      identifier,
      settings: settings,
    ).map((event) => PolarEcgData.fromJson(identifier, jsonDecode(event)));
  }

  ///  Start ACC (Accelerometer) stream. ACC stream is stopped if the connection is closed, error occurs or stream is disposed.
  ///  Requires `polarSensorStreaming` feature. Before starting the stream it is recommended to query the available settings using `requestStreamSettings`
  ///
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
      DeviceStreamingFeature.acc,
      identifier,
      settings: settings,
    ).map((event) => PolarAccData.fromJson(identifier, jsonDecode(event)));
  }

  /// Start Gyro stream. Gyro stream is stopped if the connection is closed, error occurs during start or stream is disposed.
  /// Requires `polarSensorStreaming` feature. Before starting the stream it is recommended to query the available settings using `requestStreamSettings`
  ///
  /// - Parameters:
  ///   - identifier: Polar device id or device address
  ///   - settings: selected settings to start the stream
  Stream<PolarGyroData> startGyroStreaming(
    String identifier, {
    PolarSensorSetting? settings,
  }) {
    return _startStreaming(
      DeviceStreamingFeature.gyro,
      identifier,
      settings: settings,
    ).map((event) => PolarGyroData.fromJson(identifier, jsonDecode(event)));
  }

  /// Start magnetometer stream. Magnetometer stream is stopped if the connection is closed, error occurs or stream is disposed.
  /// Requires `polarSensorStreaming` feature. Before starting the stream it is recommended to query the available settings using `requestStreamSettings`
  ///
  /// - Parameters:
  ///   - identifier: Polar device id or device address
  ///   - settings: selected settings to start the stream
  Stream<PolarMagnetometerData> startMagnetometerStreaming(
    String identifier, {
    PolarSensorSetting? settings,
  }) {
    return _startStreaming(
      DeviceStreamingFeature.magnetometer,
      identifier,
      settings: settings,
    ).map(
      (event) => PolarMagnetometerData.fromJson(identifier, jsonDecode(event)),
    );
  }

  /// Start OHR (Optical heart rate) PPG (Photoplethysmography) stream. PPG stream is stopped if the connection is closed, error occurs or stream is disposed.
  /// Requires `polarSensorStreaming` feature. Before starting the stream it is recommended to query the available settings using `requestStreamSettings`
  ///
  /// - Parameters:
  ///   - identifier: Polar device id or device address
  ///   - settings: selected settings to start the stream
  /// - Returns: Observable stream
  ///   - onNext: for every air packet received. see `PolarOhrData`
  ///   - onError: see `PolarErrors` for possible errors invoked
  Stream<PolarOhrData> startOhrStreaming(
    String identifier, {
    PolarSensorSetting? settings,
  }) {
    return _startStreaming(
      DeviceStreamingFeature.ppg,
      identifier,
      settings: settings,
    ).map((event) => PolarOhrData.fromJson(identifier, jsonDecode(event)));
  }

  /// Start OHR (Optical heart rate) PPI (Pulse to Pulse interval) stream.
  /// PPI stream is stopped if the connection is closed, error occurs or stream is disposed.
  /// Notice that there is a delay before PPI data stream starts. Requires `polarSensorStreaming` feature.
  ///
  /// - Parameters:
  ///   - identifier: Polar device id or device address
  /// - Returns: Observable stream
  ///   - onNext: for every air packet received. see `PolarPpiData`
  ///   - onError: see `PolarErrors` for possible errors invoked
  Stream<PolarPpiData> startOhrPPIStreaming(String identifier) {
    return _startStreaming(DeviceStreamingFeature.ecg, identifier)
        .map((event) => PolarPpiData.fromJson(identifier, jsonDecode(event)));
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
    return _channel.invokeMethod(
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
    return _channel.invokeMethod('stopRecording', identifier);
  }

  /// Request current recording status. Supported only by Polar H10. Requires `polarFileTransfer` feature.
  ///
  /// - Parameters:
  ///   - identifier: Polar device id
  /// - Returns: Single stream
  ///   - success: see `PolarRecordingStatus`
  ///   - onError: see `PolarErrors` for possible errors invoked
  Future<PolarRecordingStatus> requestRecordingStatus(String identifier) async {
    final result =
        await _channel.invokeListMethod('requestRecordingStatus', identifier);

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
    final result = await _channel.invokeListMethod('listExercises', identifier);
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
    final result = await _channel
        .invokeMethod('fetchExercise', [identifier, jsonEncode(entry)]);
    return PolarExerciseData.fromJson(identifier, jsonDecode(result));
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
    return _channel
        .invokeMethod('removeExercise', [identifier, jsonEncode(entry)]);
  }
}
