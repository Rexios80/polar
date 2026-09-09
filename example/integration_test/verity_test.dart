import 'dart:io';

import 'package:integration_test/integration_test.dart';
import 'package:polar/polar.dart';

import '../../test/tests.dart';

const identifier = 'ADF24B27';

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  await requestPermissions();
  testSearch(identifier);
  testConnection(identifier);
  testBasicData(identifier);
  testBleSdkFeatures(
    identifier,
    features: PolarSdkFeature.values.toSet().difference({
      PolarSdkFeature.h10ExerciseRecording,
      PolarSdkFeature.offlineExerciseV2,
      PolarSdkFeature.activityData,
      PolarSdkFeature.hts,
      PolarSdkFeature.sleepData,
      PolarSdkFeature.temperatureData,
      if (Platform.isIOS) PolarSdkFeature.offlineRecording,
      if (Platform.isAndroid) PolarSdkFeature.trainingData,
    }),
  );
  testHrService(identifier);
  testStreaming(
    identifier,
    features: {
      PolarDataType.hr,
      PolarDataType.acc,
      PolarDataType.ppg,
      PolarDataType.ppi,
      PolarDataType.gyro,
      PolarDataType.magnetometer,
    },
  );
  testSdkMode(identifier);
  testMisc(identifier, supportsLedConfig: true);
  testShutDown(identifier);
}
