import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_event_channel/mock_event_channel.dart';
import 'package:polar/polar.dart';

import 'tests.dart';

const identifier = 'asdf';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('polar'),
      handleMethodCall,
    );
    TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
        .setMockStreamHandler(
      const EventChannel('polar/search'),
      SearchHandler(),
    );
  });

  testSearch(identifier);
  // testConnection(identifier);
  // testBasicData(identifier);
  // testBleSdkFeatures(identifier, features: PolarSdkFeature.values.toSet());
  // testStreaming(identifier, features: PolarDataType.values.toSet());
  // testRecording(identifier);
}

Future<dynamic> handleMethodCall(MethodCall call) async {
  switch (call.method) {
    case 'connectToDevice':
      return null;
    case 'disconnectFromDevice':
      return null;
    case 'getAvailableOnlineStreamDataTypes':
      return null;
    case 'requestStreamSettings':
      return null;
    case 'createStreamingChannel':
      return null;
    case 'startRecording':
      return null;
    case 'stopRecording':
      return null;
    case 'requestRecordingStatus':
      return null;
    case 'listExercises':
      return null;
    case 'fetchExercise':
      return null;
    case 'removeExercise':
      return null;
    default:
      throw UnimplementedError();
  }
}

class SearchHandler extends MockStreamHandler {
  @override
  void onListen(dynamic arguments, MockStreamHandlerEventSink events) {
    events.success(
      jsonEncode(
        PolarDeviceInfo(
          deviceId: identifier,
          address: '',
          rssi: 0,
          name: '',
          isConnectable: true,
        ),
      ),
    );
  }

  @override
  void onCancel(dynamic arguments) {}
}
