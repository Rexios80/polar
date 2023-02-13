import 'package:integration_test/integration_test.dart';
import 'package:polar/polar.dart';

import 'tests.dart';

const identifier = 'AE0F8E27';

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  await requestPermissions();
  testSearch(identifier);
  testConnection(identifier);
  testBasicData(identifier);
  testBleSdkFeatures(
    identifier,
    features: PolarBleSdkFeature.values.toSet().difference({
      PolarBleSdkFeature.h10ExerciseRecording,
      PolarBleSdkFeature.sdkMode,
    }),
  );
  testStreaming(
    identifier,
    features: {
      PolarDeviceDataType.hr,
      PolarDeviceDataType.acc,
      PolarDeviceDataType.ppg,
      PolarDeviceDataType.ppi,
      PolarDeviceDataType.gyro,
      PolarDeviceDataType.magnetometer,
    },
  );
}
