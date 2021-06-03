package dev.rexios.polar

import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

import io.reactivex.rxjava3.android.schedulers.AndroidSchedulers;
import io.reactivex.rxjava3.disposables.Disposable;
import io.reactivex.rxjava3.functions.Function;

import polar.com.sdk.api.PolarBleApi;
import polar.com.sdk.api.PolarBleApiCallback;
import polar.com.sdk.api.PolarBleApiDefaultImpl;
import polar.com.sdk.api.errors.PolarInvalidArgument;
import polar.com.sdk.api.model.PolarAccelerometerData;
import polar.com.sdk.api.model.PolarDeviceInfo;
import polar.com.sdk.api.model.PolarEcgData;
import polar.com.sdk.api.model.PolarExerciseEntry;
import polar.com.sdk.api.model.PolarGyroData;
import polar.com.sdk.api.model.PolarHrData;
import polar.com.sdk.api.model.PolarMagnetometerData;
import polar.com.sdk.api.model.PolarOhrData;
import polar.com.sdk.api.model.PolarOhrPPIData;
import polar.com.sdk.api.model.PolarSensorSetting;

/** PolarPlugin */
class PolarPlugin: FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "polar")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    if (call.method == "getPlatformVersion") {
      result.success("Android ${android.os.Build.VERSION.RELEASE}")
    } else {
      result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
    this.requestPermissions(new String[]{Manifest.permission.ACCESS_FINE_LOCATION}, 1);
}
// callback is invoked after granted or denied permissions
@Override
public void onRequestPermissionsResult(int requestCode, @NonNull String permissions[], @NonNull int[] grantResults) {
}

  // NOTICE all features are enabled, if only interested on particular feature(s) like info Heart rate and Battery info then
// e.g. PolarBleApiDefaultImpl.defaultImplementation(this, PolarBleApi.FEATURE_HR |
// PolarBleApi.FEATURE_BATTERY_INFO); 
// batteryLevelReceived callback is invoked after connection
PolarBleApi api = PolarBleApiDefaultImpl.defaultImplementation(this,  PolarBleApi.ALL_FEATURES);

api.setApiCallback(new PolarBleApiCallback() {
    @Override
    public void blePowerStateChanged(boolean powered) {
        Log.d("MyApp","BLE power: " + powered);
    }

    @Override
    public void deviceConnected(@NonNull PolarDeviceInfo polarDeviceInfo) {
        Log.d("MyApp","CONNECTED: " + polarDeviceInfo.deviceId);
    }

    @Override
    public void deviceConnecting(@NonNull PolarDeviceInfo polarDeviceInfo) {
        Log.d("MyApp","CONNECTING: " + polarDeviceInfo.deviceId);
    }

    @Override
    public void deviceDisconnected(@NonNull PolarDeviceInfo polarDeviceInfo) {
        Log.d("MyApp","DISCONNECTED: " + polarDeviceInfo.deviceId);
    }

    @Override
    public void streamingFeaturesReady(@NonNull final String identifier,
                                       @NonNull final Set<PolarBleApi.DeviceStreamingFeature> features) {
            for(PolarBleApi.DeviceStreamingFeature feature : features) {
                Log.d("MyApp", "Streaming feature " + feature.toString() + " is ready");
            }
        }

    @Override
    public void hrFeatureReady(@NonNull String identifier) {
        Log.d("MyApp","HR READY: " + identifier);
    }

    @Override
    public void disInformationReceived(@NonNull String identifier, @NonNull UUID uuid, @NonNull String value) {
    }

    @Override
    public void batteryLevelReceived(@NonNull String identifier, int level) {
    }

    @Override
    public void hrNotificationReceived(@NonNull String identifier, @NonNull PolarHrData data) {
        Log.d("MyApp","HR: " + data.hr);
    }

    @Override
    public void polarFtpFeatureReady(@NonNull String s) {
    }
});

@Override
public void onPause() {
    super.onPause();
    api.backgroundEntered();
}

@Override
public void onResume() {
    super.onResume();
    api.foregroundEntered();
}

@Override
public void onDestroy() {
    super.onDestroy();
    api.shutDown();
}
}
