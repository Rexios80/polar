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

void testBasicData(String identifier, {bool sdkModeFeature = true}) {
  test('basic data', () async {
    await polar.connectToDevice(identifier);

    await Future.wait([
      polar.deviceConnectingStream.first.then((e) => expect(e, identifier)),
      polar.deviceConnectedStream.first.then((e) => expect(e, identifier)),
      if (sdkModeFeature)
        polar.sdkModeFeatureAvailableStream.first
            .then((e) => expect(e, identifier)),
      polar.hrFeatureReadyStream.first.then((e) => expect(e, identifier)),
      polar.disInformationStream.first
          .then((e) => expect(e.identifier, identifier)),
      polar.batteryLevelStream.first
          .then((e) => expect(e.level, greaterThan(0))),
      polar.heartRateStream.first
          .then((e) => expect(e.data.hr, greaterThan(0))),
      polar.ftpFeatureReadyStream.first.then((e) => expect(e, identifier)),
    ]);

    await polar.disconnectFromDevice(identifier);

    final disconnected = await polar.deviceDisconnectedStream.first;
    expect(disconnected.deviceId, identifier);
  });
}

void testStreaming(
  String identifier, {
  required List<DeviceStreamingFeature> features,
}) {
  group('streaming', () {
    setUpAll(() async {
      await polar.connectToDevice(identifier);
      final streamingFeatures = await polar.streamingFeaturesReadyStream.first;
      expect(
        setEquals(streamingFeatures.features.toSet(), features.toSet()),
        true,
      );
    });

    tearDownAll(() async {
      await polar.disconnectFromDevice(identifier);
    });

    test(
      'ecg',
      () async {
        final ecgData = await polar.startEcgStreaming(identifier).first;
        expect(ecgData.samples.length, greaterThan(0));
      },
      skip: !features.contains(DeviceStreamingFeature.ecg),
    );

    test(
      'acc',
      () async {
        final accData = await polar.startAccStreaming(identifier).first;
        expect(accData.samples.length, greaterThan(0));
      },
      skip: !features.contains(DeviceStreamingFeature.acc),
    );

    test(
      'ppg',
      () async {
        final ppgData = await polar.startOhrStreaming(identifier).first;
        expect(ppgData.samples.length, greaterThan(0));
      },
      skip: !features.contains(DeviceStreamingFeature.ppg),
    );

    test(
      'ppi',
      () async {
        final ppiData = await polar.startOhrPpiStreaming(identifier).first;
        expect(ppiData.samples.length, greaterThan(0));
      },
      skip: !features.contains(DeviceStreamingFeature.ppi),
    );

    test(
      'gyro',
      () async {
        final gyroData = await polar.startGyroStreaming(identifier).first;
        expect(gyroData.samples.length, greaterThan(0));
      },
      skip: !features.contains(DeviceStreamingFeature.gyro),
    );

    test(
      'magnetometer',
      () async {
        final magnetometerData =
            await polar.startMagnetometerStreaming(identifier).first;
        expect(magnetometerData.samples.length, greaterThan(0));
      },
      skip: !features.contains(DeviceStreamingFeature.magnetometer),
    );
  });
}

final exerciseId = const Uuid().v4();

void testRecording(String identifier) {
  test('recording', () async {
    await polar.connectToDevice(identifier);
    await polar.deviceConnectedStream.first;
    await polar.ftpFeatureReadyStream.first;

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
    final entry = entries1.firstWhere((e) => e.entryId == exerciseId);
    expect(entry.entryId, exerciseId);

    final exercise = await polar.fetchExercise(identifier, entry);
    expect(exercise.samples.length, greaterThan(0));

    await polar.removeExercise(identifier, entry);

    final entries3 = await polar.listExercises(identifier);
    expect(entries2.any((e) => e.entryId == exerciseId), false);

    await polar.disconnectFromDevice(identifier);
  });
}
