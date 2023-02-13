import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polar/polar.dart';
import 'package:uuid/uuid.dart';

final polar = Polar();

Future<void> requestPermissions() => polar.requestPermissions();

void testSearch(String identifier) {
  test('search', () async {
    await polar.searchForDevice().any((e) => e.deviceId == identifier);
    // Will fail by timeout if device is not found
  });
}

void testConnection(String identifier) {
  test('connection', () async {
    await polar.connectToDevice(identifier);

    final connecting = await polar.deviceConnectingStream.first;
    expect(connecting.deviceId, identifier);

    final connected = await polar.deviceConnectedStream.first;
    expect(connected.deviceId, identifier);

    await polar.disconnectFromDevice(identifier);

    final disconnected = await polar.deviceDisconnectedStream.first;
    expect(disconnected.deviceId, identifier);
  });
}

/// Ensure device connects
Future<void> connect(String identifier) async {
  await polar.connectToDevice(identifier);
  await polar.deviceConnectedStream.first;
}

/// Ensure device disconnects
Future<void> disconnect(String identifier) async {
  await polar.disconnectFromDevice(identifier);
  await polar.deviceDisconnectedStream.first;
}

void testBasicData(String identifier) {
  group('basic data', () {
    setUp(() async {
      await connect(identifier);
    });

    tearDown(() async {
      await disconnect(identifier);
    });

    test('disInformation', () async {
      final disInformation = await polar.disInformationStream.first;
      expect(disInformation.identifier, identifier);
    });

    test('batteryLevel', () async {
      final batteryEvent = await polar.batteryLevelStream.first;
      expect(batteryEvent.level, greaterThan(0));
    });
  });
}

void testBleSdkFeatures(
  String identifier, {
  required Set<PolarBleSdkFeature> features,
}) {
  test('Ble sdk features', () async {
    final futures = features.map(
      (feature) => polar.bleSdkFeatureReadyStream
          .firstWhere((event) => event.feature == feature),
    );

    await connect(identifier);
    await Future.wait(futures);
    await disconnect(identifier);
  });
}

void testStreaming(
  String identifier, {
  required Set<PolarDeviceDataType> features,
}) {
  group('streaming', () {
    setUpAll(() async {
      await connect(identifier);
      await polar.bleSdkFeatureReadyStream
          .firstWhere((e) => e.feature == PolarBleSdkFeature.onlineStreaming);
      final streamingFeatures =
          await polar.getAvailableOnlineStreamDataTypes(identifier);
      expect(
        setEquals(streamingFeatures, features),
        true,
      );
    });

    tearDownAll(() async {
      await disconnect(identifier);
    });

    test(
      'hr',
      () async {
        final ecgData = await polar.startHrStreaming(identifier).first;
        expect(ecgData.samples.length, greaterThan(0));
      },
      skip: !features.contains(PolarDeviceDataType.ecg),
    );

    test(
      'ecg',
      () async {
        final ecgData = await polar.startEcgStreaming(identifier).first;
        expect(ecgData.samples.length, greaterThan(0));
      },
      skip: !features.contains(PolarDeviceDataType.ecg),
    );

    test(
      'acc',
      () async {
        final accData = await polar.startAccStreaming(identifier).first;
        expect(accData.samples.length, greaterThan(0));
      },
      skip: !features.contains(PolarDeviceDataType.acc),
    );

    test(
      'ppg',
      () async {
        final ppgData = await polar.startPpgStreaming(identifier).first;
        expect(ppgData.samples.length, greaterThan(0));
      },
      skip: !features.contains(PolarDeviceDataType.ppg),
    );

    test(
      'gyro',
      () async {
        final gyroData = await polar.startGyroStreaming(identifier).first;
        expect(gyroData.samples.length, greaterThan(0));
      },
      skip: !features.contains(PolarDeviceDataType.gyro),
    );

    test(
      'magnetometer',
      () async {
        final magnetometerData =
            await polar.startMagnetometerStreaming(identifier).first;
        expect(magnetometerData.samples.length, greaterThan(0));
      },
      skip: !features.contains(PolarDeviceDataType.magnetometer),
    );

    test(
      'ppi',
      () async {
        final ppiData = await polar.startPpiStreaming(identifier).first;
        expect(ppiData.samples.length, greaterThan(0));
      },
      skip: !features.contains(PolarDeviceDataType.ppi),
    );
  });
}

final exerciseId = const Uuid().v4();

void testRecording(String identifier) {
  test('recording', () async {
    await connect(identifier);
    await polar.bleSdkFeatureReadyStream.firstWhere(
      (e) => e.feature == PolarBleSdkFeature.h10ExerciseRecording,
    );

    //! Remove existing recordings (THIS IS DESTRUCTIVE)
    // Polar H10 can only store one recording at a time
    final entries1 = await polar.listExercises(identifier);
    for (final entry in entries1) {
      await polar.removeExercise(identifier, entry);
    }

    final status1 = await polar.requestRecordingStatus(identifier);
    expect(status1.ongoing, false);

    await polar.startRecording(
      identifier,
      exerciseId: exerciseId,
      interval: RecordingInterval.interval_1s,
      sampleType: SampleType.rr,
    );

    final status2 = await polar.requestRecordingStatus(identifier);
    expect(status2.entryId, exerciseId);
    expect(status2.ongoing, true);

    await Future.delayed(const Duration(seconds: 5));
    await polar.stopRecording(identifier);

    final status3 = await polar.requestRecordingStatus(identifier);
    expect(status3.ongoing, false);

    final entries2 = await polar.listExercises(identifier);
    final entry = entries2.firstWhere((e) => e.entryId == exerciseId);
    expect(entry.entryId, exerciseId);

    final exercise = await polar.fetchExercise(identifier, entry);
    expect(exercise.samples.length, greaterThan(0));

    await polar.removeExercise(identifier, entry);

    final entries3 = await polar.listExercises(identifier);
    expect(entries3.any((e) => e.entryId == exerciseId), false);

    await disconnect(identifier);
  });
}
