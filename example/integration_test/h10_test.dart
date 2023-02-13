import 'package:integration_test/integration_test.dart';
import 'package:polar/polar.dart';

import 'tests.dart';

const identifier = '1C709B20';

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  await requestPermissions();
  testSearch(identifier);
  testConnection(identifier);
  testBasicData(identifier);
  testBleSdkFeatures(
    identifier,
    features: PolarBleSdkFeature.values.toSet(),
  );
  testStreaming(
    identifier,
    features: {
      PolarDeviceDataType.hr,
      PolarDeviceDataType.acc,
      PolarDeviceDataType.ecg,
    },
  );
  testRecording(identifier);
}
