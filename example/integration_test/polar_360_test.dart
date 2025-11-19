import 'package:integration_test/integration_test.dart';
import 'package:polar/polar.dart';

import '../../test/tests.dart';

const identifier = 'E5C32C2E';

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  await requestPermissions();
  testSearch(identifier);
  testConnection(identifier);
  testFtu(identifier);
  testBasicData(identifier);
  testBleSdkFeatures(
    identifier,
    features: PolarSdkFeature.values.toSet().difference({
      PolarSdkFeature.offlineRecording,
      PolarSdkFeature.h10ExerciseRecording,
    }),
  );
  testHrService(identifier);
  testStreaming(
    identifier,
    features: {
      PolarDataType.hr,
      PolarDataType.acc,
      PolarDataType.ppi,
      PolarDataType.temperature,
    },
  );
  testSdkMode(identifier);
  testMisc(identifier, supportsLedConfig: true);
}
