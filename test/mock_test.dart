import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polar/polar.dart';

import 'tests.dart';

const identifier = 'asdf';
final info = jsonEncode(
  PolarDeviceInfo(
    deviceId: identifier,
    address: '',
    rssi: 0,
    name: '',
    isConnectable: true,
  ),
);
const methodChannel = MethodChannel('polar/methods');
const eventChannel = EventChannel('polar/events');
const searchChannel = EventChannel('polar/search');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, handleMethodCall);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(eventChannel, EventHandler());
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(searchChannel, SearchHandler());
  });

  testSearch(identifier);
  testConnection(identifier);
  testBasicData(identifier);
  testBleSdkFeatures(identifier, features: PolarSdkFeature.values.toSet());
  testStreaming(identifier, features: PolarDataType.values.toSet());
  testRecording(identifier, wait: false);
  testSdkMode(identifier);
  testMisc(identifier, supportsLedConfig: true);
}

final exercises = <PolarExerciseEntry>[];
var recording = false;
var exerciseId = '';
var sdkModeEnabled = false;

Future<dynamic> handleMethodCall(MethodCall call) async {
  switch (call.method) {
    case 'connectToDevice':
      return null;
    case 'disconnectFromDevice':
      return null;
    case 'getAvailableOnlineStreamDataTypes':
      return jsonEncode(PolarDataType.values.map((e) => e.toJson()).toList());
    case 'requestStreamSettings':
      return jsonEncode(PolarSensorSetting({}));
    case 'createStreamingChannel':
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(
        EventChannel(call.arguments[0] as String),
        StreamingHandler(PolarDataType.fromJson(call.arguments[2])),
      );
      return null;
    case 'startRecording':
      recording = true;
      exerciseId = call.arguments[1];
      return null;
    case 'stopRecording':
      recording = false;
      exercises.add(
        PolarExerciseEntry(path: '', date: DateTime.now(), entryId: exerciseId),
      );
      return null;
    case 'requestRecordingStatus':
      return [recording, exerciseId];
    case 'listExercises':
      return exercises.map(jsonEncode).toList();
    case 'fetchExercise':
      return jsonEncode({
        'recordingInterval': 0,
        'hrSamples': [0],
      });
    case 'removeExercise':
      exercises.clear();
      return null;
    case 'setLedConfig':
      return null;
    case 'enableSdkMode':
      sdkModeEnabled = true;
      return null;
    case 'disableSdkMode':
      sdkModeEnabled = false;
      return null;
    case 'isSdkModeEnabled':
      return sdkModeEnabled;
    case 'doFactoryReset':
      return null;
    default:
      throw UnimplementedError();
  }
}

class EventHandler extends MockStreamHandler {
  @override
  void onListen(dynamic arguments, MockStreamHandlerEventSink events) {
    events.success({'event': 'deviceConnecting', 'data': info});
    events.success({'event': 'deviceConnected', 'data': info});
    events.success({
      'event': 'disInformationReceived',
      'data': [identifier, '', ''],
    });
    events.success({
      'event': 'batteryLevelReceived',
      'data': [identifier, 100],
    });
    events.success({
      'event': 'batteryChargingStatusReceived',
      'data': [
        identifier,
        jsonEncode(PolarChargeState.dischargingActive.toJson()),
      ],
    });
    for (final feature in PolarSdkFeature.values) {
      events.success({
        'event': 'sdkFeatureReady',
        'data': [identifier, feature.toJson()],
      });
    }

    events.success({
      'event': 'deviceDisconnected',
      'data': [info, false],
    });
  }

  @override
  void onCancel(dynamic arguments) {}
}

class SearchHandler extends MockStreamHandler {
  @override
  void onListen(dynamic arguments, MockStreamHandlerEventSink events) {
    events.success(info);
  }

  @override
  void onCancel(dynamic arguments) {}
}

class StreamingHandler extends MockStreamHandler {
  final PolarDataType type;

  StreamingHandler(this.type);

  @override
  void onListen(dynamic arguments, MockStreamHandlerEventSink events) {
    final PolarStreamingData data;
    switch (type) {
      case PolarDataType.ecg:
        data = PolarEcgData(
          samples: [PolarEcgSample(timeStamp: DateTime.now(), voltage: 0)],
        );
      case PolarDataType.acc:
        data = PolarAccData(
          samples: [
            PolarAccSample(timeStamp: DateTime.now(), x: 0, y: 0, z: 0),
          ],
        );
      case PolarDataType.ppg:
        data = PolarPpgData(
          type: PpgDataType.ppg3_ambient1,
          samples: [
            PolarPpgSample(timeStamp: DateTime.now(), channelSamples: []),
          ],
        );
      case PolarDataType.ppi:
        data = PolarPpiData(
          samples: [
            PolarPpiSample(
              timeStamp: 0,
              ppi: 0,
              errorEstimate: 0,
              hr: 0,
              blockerBit: false,
              skinContactStatus: false,
              skinContactSupported: false,
            ),
          ],
        );
      case PolarDataType.gyro:
        data = PolarGyroData(
          samples: [
            PolarGyroSample(timeStamp: DateTime.now(), x: 0, y: 0, z: 0),
          ],
        );
      case PolarDataType.magnetometer:
        data = PolarMagnetometerData(
          samples: [
            PolarMagnetometerSample(
              timeStamp: DateTime.now(),
              x: 0,
              y: 0,
              z: 0,
            ),
          ],
        );
      case PolarDataType.hr:
        data = PolarHrData(
          samples: [
            PolarHrSample(
              hr: 0,
              ppgQuality: 0,
              correctedHr: 0,
              rrsMs: [],
              contactStatus: false,
              contactStatusSupported: false,
            ),
          ],
        );
      case PolarDataType.temperature:
        data = PolarTemperatureData(
          samples: [
            PolarTemperatureSample(
              timeStamp: DateTime.now(),
              temperature: 0,
            ),
          ],
        );
      case PolarDataType.pressure:
        data = PolarPressureData(
          samples: [
            PolarPressureSample(
              timeStamp: DateTime.now(),
              pressure: 0,
            ),
          ],
        );
      case PolarDataType.skinTemperature:
        data = PolarTemperatureData(
          samples: [
            PolarTemperatureSample(
              timeStamp: DateTime.now(),
              temperature: 0,
            ),
          ],
        );
      case PolarDataType.location:
        data = PolarLocationData(
          samples: [
            PolarLocationDataSample(
              timeStamp: DateTime.now(),
              latitude: 0,
              longitude: 0,
              time: '',
              speed: 0,
              cumulativeDistance: 0,
              usedAccelerationSpeed: 0,
              coordinateSpeed: 0,
              accelerationSpeedFactor: 0,
              course: 0,
              gpsChipSpeed: 0,
              fix: true,
              speedFlag: 0,
              fusionState: 0,
            ),
          ],
        );
    }

    events.success(jsonEncode(data));
  }

  @override
  void onCancel(dynamic arguments) {}
}
