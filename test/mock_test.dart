import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_event_channel/mock_event_channel.dart';
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
const channel = MethodChannel('polar');
const searchChannel = EventChannel('polar/search');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, handleMethodCall);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(searchChannel, SearchHandler());
  });

  testSearch(identifier);
  testConnection(identifier);
  testBasicData(identifier);
  testBleSdkFeatures(identifier, features: PolarSdkFeature.values.toSet());
  testStreaming(identifier, features: PolarDataType.values.toSet());
  testRecording(identifier, wait: false);
}

Future<void> invoke(String method, [dynamic arguments]) {
  return TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(
    channel.name,
    channel.codec.encodeMethodCall(MethodCall(method, arguments)),
    null,
  );
}

void executeLater<T>(FutureOr<T> Function() computation) {
  Future.delayed(Duration.zero, computation);
}

final exercises = <PolarExerciseEntry>[];
var recording = false;
var exerciseId = '';

Future<dynamic> handleMethodCall(MethodCall call) async {
  switch (call.method) {
    case 'connectToDevice':
      executeLater(() async {
        await invoke('deviceConnecting', info);
        await invoke('deviceConnected', info);
        await invoke('disInformationReceived', [identifier, '', '']);
        await invoke('batteryLevelReceived', [identifier, 100]);
        for (final feature in PolarSdkFeature.values) {
          await invoke('sdkFeatureReady', [identifier, feature.toJson()]);
        }
      });
      return null;
    case 'disconnectFromDevice':
      executeLater(() => invoke('deviceDisconnected', [info, false]));
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
        'hrSamples': [0]
      });
    case 'removeExercise':
      exercises.clear();
      return null;
    default:
      throw UnimplementedError();
  }
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
        break;
      case PolarDataType.acc:
        data = PolarAccData(
          samples: [
            PolarAccSample(timeStamp: DateTime.now(), x: 0, y: 0, z: 0),
          ],
        );
        break;
      case PolarDataType.ppg:
        data = PolarPpgData(
          type: PpgDataType.ppg3_ambient1,
          samples: [
            PolarPpgSample(timeStamp: DateTime.now(), channelSamples: []),
          ],
        );
        break;
      case PolarDataType.ppi:
        data = PolarPpiData(
          samples: [
            PolarPpiSample(
              ppi: 0,
              errorEstimate: 0,
              hr: 0,
              blockerBit: false,
              skinContactStatus: false,
              skinContactSupported: false,
            ),
          ],
        );
        break;
      case PolarDataType.gyro:
        data = PolarGyroData(
          samples: [
            PolarGyroSample(timeStamp: DateTime.now(), x: 0, y: 0, z: 0),
          ],
        );
        break;
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
        break;
      case PolarDataType.hr:
        data = PolarHrData(
          samples: [
            PolarHrSample(
              hr: 0,
              rrsMs: [],
              contactStatus: false,
              contactStatusSupported: false,
            ),
          ],
        );
        break;
    }

    events.success(jsonEncode(data));
  }

  @override
  void onCancel(dynamic arguments) {}
}
