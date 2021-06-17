part of 'polar.dart';

class PolarStreamingFeaturesReadyEvent {
  final String identifier;
  final List<DeviceStreamingFeature> features;

  PolarStreamingFeaturesReadyEvent(this.identifier, this.features);
}

class PolarDisInformationEvent {
  final String identifier;
  final String uuid;
  final String info;

  PolarDisInformationEvent(this.identifier, this.uuid, this.info);
}

class PolarBatteryLevelEvent {
  final String identifier;
  final int level;

  PolarBatteryLevelEvent(this.identifier, this.level);
}

class PolarHeartRateEvent {
  final String identifier;
  final PolarHrData data;

  PolarHeartRateEvent(this.identifier, this.data);
}
