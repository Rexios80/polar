import 'package:integration_test/integration_test.dart';
import 'package:polar/polar.dart';

import '../../test/tests.dart';

const identifier = '1C709B20';

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
      PolarSdkFeature.sdkMode,
      PolarSdkFeature.ledAnimation,
      PolarSdkFeature.activityData,
      PolarSdkFeature.fileTransfer,
      PolarSdkFeature.hts,
      PolarSdkFeature.sleepData,
      PolarSdkFeature.temperatureData,
    }),
  );
  testStreaming(
    identifier,
    features: {
      PolarDataType.hr,
      PolarDataType.acc,
      PolarDataType.ecg,
    },
  );
  testRecording(identifier);
  testMisc(identifier, supportsLedConfig: false);
}
