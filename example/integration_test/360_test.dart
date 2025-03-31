import 'package:integration_test/integration_test.dart';
import 'package:polar/polar.dart';

import '../../test/tests.dart';

const identifier = 'E0729E20';

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  await requestPermissions();
  testSearch(identifier);
  testConnection(identifier);

  /// TODO: Add FTU
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
      PolarDataType.ppi,
      PolarDataType.skinTemperature
    },
  );
  testSdkMode(identifier);
  testMisc(identifier, isVerity: true);
}
