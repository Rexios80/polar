package dev.rexios.polar

import android.content.Context
import androidx.annotation.NonNull
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.Lifecycle.Event
import androidx.lifecycle.LifecycleEventObserver
import com.google.gson.Gson
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
    private lateinit var api: PolarBleApi

    private val gson = Gson()

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "polar")
        channel.setMethodCallHandler(this)

        api = PolarBleApiDefaultImpl.defaultImplementation(flutterPluginBinding.applicationContext, PolarBleApi.ALL_FEATURES)
        api.setApiCallback(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "connectToDevice" -> api.connectToDevice(call.arguments as String)
            "disconnectFromDevice" -> api.disconnectFromDevice(call.arguments as String)
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(p0: ActivityPluginBinding) {
        (p0.lifecycle as Lifecycle).addObserver(LifecycleEventObserver { _, event ->
            when (event) {
                Event.ON_PAUSE -> api.backgroundEntered()
                Event.ON_RESUME -> api.foregroundEntered()
                Event.ON_DESTROY -> api.shutDown()
                else -> {
                }
            }
        })
    }

    override fun onDetachedFromActivityForConfigChanges() {}

    override fun onReattachedToActivityForConfigChanges(p0: ActivityPluginBinding) {}

    override fun onDetachedFromActivity() {}

    override fun blePowerStateChanged(p0: Boolean) {
        channel.invokeMethod("blePowerStateChanged", p0)
    }

    override fun deviceConnected(p0: PolarDeviceInfo) {
        channel.invokeMethod("deviceConnected", gson.toJson(p0))
    }

    override fun deviceConnecting(p0: PolarDeviceInfo) {
        channel.invokeMethod("deviceConnecting", gson.toJson(p0))
    }

    override fun deviceDisconnected(p0: PolarDeviceInfo) {
        channel.invokeMethod("deviceDisconnected", gson.toJson(p0))
    }

    override fun streamingFeaturesReady(
        p0: String,
        p1: MutableSet<PolarBleApi.DeviceStreamingFeature>
    ) {
        channel.invokeMethod("streamingFeaturesReady", listOf(p0, gson.toJson(p1)))
    }

    override fun sdkModeFeatureAvailable(p0: String) {
        channel.invokeMethod("sdkModeFeatureAvailable", p0)
    }

    override fun hrFeatureReady(p0: String) {
        channel.invokeMethod("hrFeatureReady", p0)
    }

    override fun disInformationReceived(p0: String, p1: UUID, p2: String) {
        channel.invokeMethod("disInformationReceived", listOf(p0, p1.toString(), p2))
    }

    override fun batteryLevelReceived(p0: String, p1: Int) {
        channel.invokeMethod("batteryLevelReceived", listOf(p0, p1))
    }

    override fun hrNotificationReceived(p0: String, p1: PolarHrData) {
        channel.invokeMethod("hrNotificationReceived", listOf(p0, gson.toJson(p1)))
    }

    override fun polarFtpFeatureReady(p0: String) {
        channel.invokeMethod("polarFtpFeatureReady", p0)
    }
}
