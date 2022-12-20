import 'package:integration_test/integration_test.dart';
import 'package:polar/polar.dart';

import 'tests.dart';

const identifier = '2021DJ1605';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testSearch(identifier);
  testConnection(identifier);
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
