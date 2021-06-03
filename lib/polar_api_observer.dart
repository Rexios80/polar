part of 'polar.dart';

abstract class PolarApiObserver {
  void blePowerStateChanged(bool state);
  void deviceConnected(PolarDeviceInfo info);
  void deviceConnecting(PolarDeviceInfo info);
  void deviceDisconnected(PolarDeviceInfo info);
  void streamingFeaturesReady(
    String deviceId,
    List<DeviceStreamingFeature> features,
  );
  void sdkModeFeatureAvailable(String deviceId);
  void hrFeatureReady(String deviceId);
  void disInformationReceived(String deviceId, String uuid, String info);
  void batteryLevelReceived(String deviceId, int level);
  void hrNotificationReceived(String deviceId, PolarHrData data);
  void polarFtpFeatureReady(String deviceId);
}
