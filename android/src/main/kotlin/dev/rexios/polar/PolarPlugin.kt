package dev.rexios.polar

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
import polar.com.sdk.api.model.PolarSensorSetting
import java.util.*

/** PolarPlugin */
class PolarPlugin : FlutterPlugin, MethodCallHandler, PolarBleApiCallbackProvider, ActivityAware {
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

    fun startEcgStreaming(identifier: String, settings: PolarSensorSetting) {
        api.startEcgStreaming(identifier, settings).subscribe {
            channel.invokeMethod("ecgDataReceived", gson.toJson(it))
        }
    }

    fun startAccStreaming(identifier: String, settings: PolarSensorSetting) {
        api.startAccStreaming(identifier, settings).subscribe {
            channel.invokeMethod("accDataReceived", gson.toJson(it))
        }
    }

    fun startGyroStreaming(identifier: String, settings: PolarSensorSetting) {
        api.startGyroStreaming(identifier, settings).subscribe {
            channel.invokeMethod("gyroDataReceived", gson.toJson(it))
        }
    }

    fun startMagnetometerStreaming(identifier: String, settings: PolarSensorSetting) {
        api.startMagnetometerStreaming(identifier, settings).subscribe {
            channel.invokeMethod("magnetometerDataReceived", gson.toJson(it))
        }
    }

    fun startOhrStreaming(identifier: String, settings: PolarSensorSetting) {
        api.startOhrStreaming(identifier, settings).subscribe {
            channel.invokeMethod("ohrDataReceived", gson.toJson(it))
        }
    }

    fun startOhrPPIStreaming(identifier: String) {
        api.startOhrPPIStreaming(identifier).subscribe {
            channel.invokeMethod("ohrPPIReceived", gson.toJson(it))
        }
    }

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
