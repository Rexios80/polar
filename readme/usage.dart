import 'package:flutter/foundation.dart';
import 'package:polar/polar.dart';

const identifier = '1C709B20';
final polar = Polar();

void example() {
  polar.heartRateStream.listen((e) => debugPrint('Heart rate: ${e.data.hr}'));
  polar.streamingFeaturesReadyStream.listen((e) {
    if (e.features.contains(DeviceStreamingFeature.ecg)) {
      polar
          .startEcgStreaming(e.identifier)
          .listen((e) => debugPrint('ECG data: ${e.samples}'));
    }
  });
  polar.connectToDevice(identifier);
}
