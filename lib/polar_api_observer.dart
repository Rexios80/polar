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

  /// Called when the given [features] are ready for the given [identifier]
  void streamingFeaturesReady(
    String identifier,
    List<DeviceStreamingFeature> features,
  );

  /// Called when sdk mode is available for the given [identifier]
  void sdkModeFeatureAvailable(String identifier);

  /// Called when the hr feature is ready for the given [identifier]
  void hrFeatureReady(String identifier);

  /// Called when dis information is received from the given [identifier]
  void disInformationReceived(String identifier, String uuid, String info);

  /// Called when a battery [level] is received from the given [identifier]
  void batteryLevelReceived(String identifier, int level);

  /// Called when hr [data] is received from the given [identifier]
  void hrNotificationReceived(String identifier, PolarHrData data);

  /// Called when the polar ftp feature is ready for the given [identifier]
  void polarFtpFeatureReady(String identifier);
}
