import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'led_config.g.dart';

/// Configuration for the LEDs on the Polar device
@JsonSerializable()
@immutable
class LedConfig {
  /// Whether the SDK mode LED is enabled
  final bool sdkModeLedEnabled;

  /// Whether the PPI mode LED is enabled
  final bool ppiModeLedEnabled;

  /// Constructor
  const LedConfig({
    this.sdkModeLedEnabled = true,
    this.ppiModeLedEnabled = true,
  });

  /// From json
  factory LedConfig.fromJson(Map<String, dynamic> json) =>
      _$LedConfigFromJson(json);

  /// To json
  Map<String, dynamic> toJson() => _$LedConfigToJson(this);
}
