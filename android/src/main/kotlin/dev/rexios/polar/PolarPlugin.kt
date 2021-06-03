package dev.rexios.polar

import android.content.Context
import androidx.annotation.NonNull
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.Lifecycle.Event
import androidx.lifecycle.LifecycleEventObserver
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import polar.com.sdk.api.PolarBleApi
import polar.com.sdk.api.PolarBleApiCallbackProvider
import polar.com.sdk.api.PolarBleApiDefaultImpl
import polar.com.sdk.api.model.PolarDeviceInfo
import polar.com.sdk.api.model.PolarHrData
import java.util.*

/** PolarPlugin */
class PolarPlugin : FlutterPlugin, MethodCallHandler, PolarBleApiCallbackProvider, ActivityAware {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var api: PolarBleApi? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "polar")
        channel.setMethodCallHandler(this)

        context = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "start" -> start(call.arguments as String)
            "stop" -> stop()
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    private fun start(deviceId: String) {
        // TODO: Do in plugin
//      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
//        this.requestPermissions(new String[]{Manifest.permission.ACCESS_FINE_LOCATION}, 1);
//      }
//// callback is invoked after granted or denied permissions
//      @Override
//      public void onRequestPermissionsResult(int requestCode, @NonNull String permissions[], @NonNull int[] grantResults) {
//      }

        // NOTICE all features are enabled, if only interested on particular feature(s) like info Heart rate and Battery info then
// e.g. PolarBleApiDefaultImpl.defaultImplementation(this, PolarBleApi.FEATURE_HR |
// PolarBleApi.FEATURE_BATTERY_INFO);
// batteryLevelReceived callback is invoked after connection
        api = PolarBleApiDefaultImpl.defaultImplementation(context, PolarBleApi.ALL_FEATURES)
        api?.setApiCallback(this)
        api?.connectToDevice(deviceId)
    }

    private fun stop() {
        api?.shutDown()
    }

    override fun onAttachedToActivity(p0: ActivityPluginBinding) {
        (p0.lifecycle as Lifecycle).addObserver(LifecycleEventObserver { _, event ->
            when (event) {
                Event.ON_PAUSE -> api?.backgroundEntered()
                Event.ON_RESUME -> api?.foregroundEntered()
                Event.ON_DESTROY -> api?.shutDown()
                else -> {
                }
            }
        })
    }

    override fun onDetachedFromActivityForConfigChanges() {}

    override fun onReattachedToActivityForConfigChanges(p0: ActivityPluginBinding) {}

    override fun onDetachedFromActivity() {}

    override fun blePowerStateChanged(p0: Boolean) {}

    override fun deviceConnected(p0: PolarDeviceInfo) {
        channel.invokeMethod("connection", true)
    }

    override fun deviceConnecting(p0: PolarDeviceInfo) {}

    override fun deviceDisconnected(p0: PolarDeviceInfo) {
        channel.invokeMethod("connection", false)
    }

    override fun streamingFeaturesReady(
        p0: String,
        p1: MutableSet<PolarBleApi.DeviceStreamingFeature>
    ) {
    }

    override fun sdkModeFeatureAvailable(p0: String) {}

    override fun hrFeatureReady(p0: String) {}

    override fun disInformationReceived(p0: String, p1: UUID, p2: String) {}

    override fun batteryLevelReceived(p0: String, p1: Int) {
        channel.invokeMethod("battery", p1)
    }

    override fun hrNotificationReceived(p0: String, p1: PolarHrData) {
        channel.invokeMethod("hr", p1.hr)
        channel.invokeMethod("rrs", p1.rrs)
    }

    override fun polarFtpFeatureReady(p0: String) {}
}
