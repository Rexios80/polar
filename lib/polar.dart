import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class Polar {
  static const MethodChannel _channel = const MethodChannel('polar');
  final _connectionStreamController = StreamController<bool>.broadcast();
  final _hrStreamController = StreamController<int>.broadcast();
  final _rrsStreamController = StreamController<List<int>>.broadcast();

  Stream<bool> get connectionStream => _connectionStreamController.stream;
  Stream<int> get hrStream => _hrStreamController.stream;
  Stream<List<int>> get rrsStream => _rrsStreamController.stream;

  Polar() {
    _channel.setMethodCallHandler((call) {
      switch (call.method) {
        case 'connection':
          _connectionStreamController.add(call.arguments);
          break;
        case 'hr':
          _hrStreamController.add(call.arguments);
          break;
        case 'rrs':
          _rrsStreamController.add(call.arguments);
          break;
      }

      return Future.value();
    });
  }

  /// Start the API with the given [deviceId]
  void start(String deviceId) async {
    if (Platform.isAndroid) {
      await Permission.location.request();
    }

    _channel.invokeMethod('start', deviceId);
  }

  /// Stop the API
  void stop() {
    _channel.invokeMethod('stop');
  }

  /// Close all stream sinks
  void destroy() {
    _connectionStreamController.close();
    _hrStreamController.close();
    _rrsStreamController.close();
  }
}
