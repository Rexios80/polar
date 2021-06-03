
import 'dart:async';

import 'package:flutter/services.dart';

class Polar {
  static const MethodChannel _channel =
      const MethodChannel('polar');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
