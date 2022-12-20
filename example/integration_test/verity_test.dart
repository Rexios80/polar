import 'package:integration_test/integration_test.dart';
import 'package:polar/polar.dart';

import 'tests.dart';

const identifier = 'AE0F8E27';

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  await requestPermissions();
  testSearch(identifier);
  testBasicData(identifier);
  testStreaming(
    identifier,
    features: [
      DeviceStreamingFeature.acc,
      DeviceStreamingFeature.ppg,
      DeviceStreamingFeature.ppi,
      DeviceStreamingFeature.gyro,
      DeviceStreamingFeature.magnetometer,
    ],
  );
}
