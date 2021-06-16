package dev.rexios.polar

import android.os.Handler
import android.os.Looper
import androidx.annotation.NonNull
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.Lifecycle.Event
import androidx.lifecycle.LifecycleEventObserver
import com.google.gson.Gson
import io.flutter.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import polar.com.sdk.api.PolarBleApi
import polar.com.sdk.api.PolarBleApi.DeviceStreamingFeature
import polar.com.sdk.api.PolarBleApiCallbackProvider
import polar.com.sdk.api.PolarBleApiDefaultImpl
import polar.com.sdk.api.model.PolarDeviceInfo
import polar.com.sdk.api.model.PolarHrData
import polar.com.sdk.api.model.PolarSensorSetting
import java.util.*

/** PolarPlugin */
class PolarPlugin : FlutterPlugin, MethodCallHandler, PolarBleApiCallbackProvider, ActivityAware {
    private val tag = "PolarPlugin"
    private lateinit var channel: MethodChannel
    private lateinit var api: PolarBleApi

    private val gson = Gson()

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "polar")
        channel.setMethodCallHandler(this)

        api = PolarBleApiDefaultImpl.defaultImplementation(
            flutterPluginBinding.applicationContext,
            PolarBleApi.ALL_FEATURES
        )
        api.setApiCallback(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "connectToDevice" -> api.connectToDevice(call.arguments as String)
            "disconnectFromDevice" -> api.disconnectFromDevice(call.arguments as String)
            "requestStreamSettings" -> {
                val arguments = call.arguments as List<*>
                requestStreamSettings(
                    arguments[0] as String,
                    gson.fromJson(
                        arguments[1] as String,
                        PolarBleApi.DeviceStreamingFeature::class.java
                    ),
                    result
                )
            }
            "startEcgStreaming" -> {
                val arguments = call.arguments as List<*>
                startEcgStreaming(
                    arguments[0] as String,
                    gson.fromJson(arguments[1] as String, PolarSensorSetting::class.java)
                )
            }
            "startAccStreaming" -> {
                val arguments = call.arguments as List<*>
                startAccStreaming(
                    arguments[0] as String,
                    gson.fromJson(arguments[1] as String, PolarSensorSetting::class.java)
                )
            }
            "startGyroStreaming" -> {
                val arguments = call.arguments as List<*>
                startGyroStreaming(
                    arguments[0] as String,
                    gson.fromJson(arguments[1] as String, PolarSensorSetting::class.java)
                )
            }
            "startMagnetometerStreaming" -> {
                val arguments = call.arguments as List<*>
                startMagnetometerStreaming(
                    arguments[0] as String,
                    gson.fromJson(arguments[1] as String, PolarSensorSetting::class.java)
                )
            }
            "startOhrStreaming" -> {
                val arguments = call.arguments as List<*>
                startOhrStreaming(
                    arguments[0] as String,
                    gson.fromJson(arguments[1] as String, PolarSensorSetting::class.java)
                )
            }
            "startOhrPPIStreaming" -> startOhrPPIStreaming(call.arguments as String)
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

    // Apparently you have to call invokeMethod on the UI thread
    private fun invokeOnUiThread(method: String, arguments: Any?, callback: Result? = null) {
        Handler(Looper.getMainLooper()).post {
            channel.invokeMethod(method, arguments, callback)
        }
    }

    private fun requestStreamSettings(
        identifier: String,
        feature: DeviceStreamingFeature,
        result: Result
    ) {
        api.requestStreamSettings(identifier, feature).subscribe({
            result.success(it)
        }, { result.error(it.localizedMessage, null, null) })
    }

    private fun startEcgStreaming(identifier: String, settings: PolarSensorSetting) {
        api.startEcgStreaming(identifier, settings).subscribe({
            invokeOnUiThread("ecgDataReceived", gson.toJson(it))
        }, { Log.e(tag, it.localizedMessage ?: "Unknown ecgStreaming error") })
    }

    private fun startAccStreaming(identifier: String, settings: PolarSensorSetting) {
        api.startAccStreaming(identifier, settings).subscribe({
            invokeOnUiThread("accDataReceived", gson.toJson(it))
        }, { Log.e(tag, it.localizedMessage ?: "Unknown accStreaming error") })
    }

    private fun startGyroStreaming(identifier: String, settings: PolarSensorSetting) {
        api.startGyroStreaming(identifier, settings).subscribe({
            invokeOnUiThread("gyroDataReceived", gson.toJson(it))
        }, { Log.e(tag, it.localizedMessage ?: "Unknown gyroStreaming error") })
    }

    private fun startMagnetometerStreaming(identifier: String, settings: PolarSensorSetting) {
        api.startMagnetometerStreaming(identifier, settings).subscribe({
            invokeOnUiThread("magnetometerDataReceived", gson.toJson(it))
        }, { Log.e(tag, it.localizedMessage ?: "Unknown magnetometerStreaming error") })
    }

    private fun startOhrStreaming(identifier: String, settings: PolarSensorSetting) {
        api.startOhrStreaming(identifier, settings).subscribe({
            invokeOnUiThread("ohrDataReceived", gson.toJson(it))
        }, { Log.e(tag, it.localizedMessage ?: "Unknown ohrStreaming error") })
    }

    private fun startOhrPPIStreaming(identifier: String) {
        api.startOhrPPIStreaming(identifier).subscribe({
            invokeOnUiThread("ohrPPIReceived", gson.toJson(it))
        }, { Log.e(tag, it.localizedMessage ?: "Unknown ohrPPIStreaming error") })
    }

    override fun blePowerStateChanged(p0: Boolean) {
        invokeOnUiThread("blePowerStateChanged", p0)
    }

    override fun deviceConnected(p0: PolarDeviceInfo) {
        invokeOnUiThread("deviceConnected", gson.toJson(p0))
    }

    override fun deviceConnecting(p0: PolarDeviceInfo) {
        invokeOnUiThread("deviceConnecting", gson.toJson(p0))
    }

    override fun deviceDisconnected(p0: PolarDeviceInfo) {
        invokeOnUiThread("deviceDisconnected", gson.toJson(p0))
    }

    override fun streamingFeaturesReady(
        p0: String,
        p1: MutableSet<DeviceStreamingFeature>
    ) {
        invokeOnUiThread("streamingFeaturesReady", listOf(p0, gson.toJson(p1)))
    }

    override fun sdkModeFeatureAvailable(p0: String) {
        invokeOnUiThread("sdkModeFeatureAvailable", p0)
    }

    override fun hrFeatureReady(p0: String) {
        invokeOnUiThread("hrFeatureReady", p0)
    }

    override fun disInformationReceived(p0: String, p1: UUID, p2: String) {
        invokeOnUiThread("disInformationReceived", listOf(p0, p1.toString(), p2))
    }

    override fun batteryLevelReceived(p0: String, p1: Int) {
        invokeOnUiThread("batteryLevelReceived", listOf(p0, p1))
    }

    override fun hrNotificationReceived(p0: String, p1: PolarHrData) {
        invokeOnUiThread("hrNotificationReceived", listOf(p0, gson.toJson(p1)))
    }

    override fun polarFtpFeatureReady(p0: String) {
        invokeOnUiThread("polarFtpFeatureReady", p0)
    }
}
