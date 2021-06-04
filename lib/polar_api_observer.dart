part of 'polar.dart';

/// Dart wrapper for the PolarApiObserver
abstract class PolarApiObserver {
  /// Called when the BLE power state changes
  void blePowerStateChanged(bool state);

  /// Called when a Polar device connects
  void deviceConnected(PolarDeviceInfo info);

  /// Called when a Polar device is connecting
  void deviceConnecting(PolarDeviceInfo info);

  /// Called when a Polar device disconnects
  void deviceDisconnected(PolarDeviceInfo info);

  /// Called when the given [features] are ready for the given [deviceId]
  void streamingFeaturesReady(
    String deviceId,
    List<DeviceStreamingFeature> features,
  );

  /// Called when sdk mode is available for the given [deviceId]
  void sdkModeFeatureAvailable(String deviceId);

  /// Called when the hr feature is ready for the given [deviceId]
  void hrFeatureReady(String deviceId);

  /// Called when dis information is received from the given [deviceId]
  void disInformationReceived(String deviceId, String uuid, String info);

  /// Called when a battery [level] is received from the given [deviceId]
  void batteryLevelReceived(String deviceId, int level);

  /// Called when hr [data] is received from the given [deviceId]
  void hrNotificationReceived(String deviceId, PolarHrData data);

  /// Called when the polar ftp feature is ready for the given [deviceId]
  void polarFtpFeatureReady(String deviceId);
}
