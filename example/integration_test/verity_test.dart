import 'package:integration_test/integration_test.dart';
import 'package:polar/polar.dart';

import '../../test/tests.dart';

const identifier = 'AE0F8E27';

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  await requestPermissions();
  testSearch(identifier);
  testConnection(identifier);
  testBasicData(identifier);
  testBleSdkFeatures(
    identifier,
    features: PolarSdkFeature.values.toSet().difference({
      PolarSdkFeature.offlineRecording,
      PolarSdkFeature.h10ExerciseRecording,
    }),
  );
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
  testMisc(identifier, isVerity: true);
}
