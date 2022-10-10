package dev.rexios.polar

import android.os.Handler
import android.os.Looper
import androidx.lifecycle.Lifecycle.Event
import androidx.lifecycle.LifecycleEventObserver
import com.google.gson.Gson
import com.polar.sdk.api.PolarBleApi
import com.polar.sdk.api.PolarBleApiCallbackProvider
import com.polar.sdk.api.PolarBleApiDefaultImpl
import com.polar.sdk.api.model.PolarDeviceInfo
import com.polar.sdk.api.model.PolarHrData
import com.polar.sdk.api.model.PolarSensorSetting
import io.flutter.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.embedding.engine.plugins.lifecycle.FlutterLifecycleAdapter
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.reactivex.rxjava3.disposables.Disposable
import java.util.*

fun Any?.discard() = Unit

/** PolarPlugin */
class PolarPlugin : FlutterPlugin, MethodCallHandler, PolarBleApiCallbackProvider, ActivityAware {
    private val tag = "Polar"
    private lateinit var channel: MethodChannel
    private lateinit var searchChannel: EventChannel
    private lateinit var api: PolarBleApi

    private val gson = Gson()

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "polar")
        channel.setMethodCallHandler(this)

        searchChannel = EventChannel(flutterPluginBinding.binaryMessenger, "polar/search")
        searchChannel.setStreamHandler(searchHandler)

        api = PolarBleApiDefaultImpl.defaultImplementation(
            flutterPluginBinding.applicationContext,
            PolarBleApi.ALL_FEATURES
        )
        api.setApiCallback(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        shutdown()
    }

    private var searchSubscription: Disposable? = null
    private val searchHandler = object : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
            searchSubscription = api.searchForDevice().subscribe({
                sink.success(gson.toJson(it))
            }, {
                sink.error(it.localizedMessage ?: "Unknown error searching for device", null, null)
            })
        }

        override fun onCancel(arguments: Any) {
            searchSubscription?.dispose()
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "connectToDevice" -> {
                api.connectToDevice(call.arguments as String)
                result.success(null)
            }

            "disconnectFromDevice" -> {
                api.disconnectFromDevice(call.arguments as String)
                result.success(null)
            }

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
                result.success(null)
            }

            "startAccStreaming" -> {
                val arguments = call.arguments as List<*>
                startAccStreaming(
                    arguments[0] as String,
                    gson.fromJson(arguments[1] as String, PolarSensorSetting::class.java)
                )
                result.success(null)
            }

            "startGyroStreaming" -> {
                val arguments = call.arguments as List<*>
                startGyroStreaming(
                    arguments[0] as String,
                    gson.fromJson(arguments[1] as String, PolarSensorSetting::class.java)
                )
                result.success(null)
            }

            "startMagnetometerStreaming" -> {
                val arguments = call.arguments as List<*>
                startMagnetometerStreaming(
                    arguments[0] as String,
                    gson.fromJson(arguments[1] as String, PolarSensorSetting::class.java)
                )
                result.success(null)
            }

            "startOhrStreaming" -> {
                val arguments = call.arguments as List<*>
                startOhrStreaming(
                    arguments[0] as String,
                    gson.fromJson(arguments[1] as String, PolarSensorSetting::class.java)
                )
                result.success(null)
            }

            "startOhrPPIStreaming" -> {
                startOhrPPIStreaming(call.arguments as String)
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        val lifecycle = FlutterLifecycleAdapter.getActivityLifecycle(binding)
        lifecycle.addObserver(LifecycleEventObserver { _, event ->
            when (event) {
                Event.ON_RESUME -> api.foregroundEntered()
                Event.ON_DESTROY -> shutdown()
                else -> {}
            }
        })
    }

    override fun onDetachedFromActivityForConfigChanges() {}
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {}
    override fun onDetachedFromActivity() {}

    // Apparently you have to call invokeMethod on the UI thread
    private fun invokeOnUiThread(method: String, arguments: Any?, callback: Result? = null) {
        runOnUiThread { channel.invokeMethod(method, arguments, callback) }
    }

    private fun runOnUiThread(runnable: () -> Unit) {
        Handler(Looper.getMainLooper()).post { runnable() }
    }

    private fun shutdown() {
        try {
            api.shutDown()
        } catch (e: Exception) {
            // This will throw if the api is already shut down
        }
    }

    private fun requestStreamSettings(
        identifier: String,
        feature: PolarBleApi.DeviceStreamingFeature,
        result: Result
    ) {
        api.requestStreamSettings(identifier, feature).subscribe({
            runOnUiThread { result.success(gson.toJson(it)) }
        }, {
            runOnUiThread {
                result.error(
                    it.localizedMessage ?: "Unknown error requesting streaming settings",
                    null,
                    null,
                )
            }
        }).discard()
    }

    private fun startEcgStreaming(identifier: String, settings: PolarSensorSetting) {
        api.startEcgStreaming(identifier, settings).subscribe({
            invokeOnUiThread("ecgDataReceived", listOf(identifier, gson.toJson(it)))
        }, { Log.e(tag, it.localizedMessage ?: "Unknown ecgStreaming error") }).discard()
    }

    private fun startAccStreaming(identifier: String, settings: PolarSensorSetting) {
        api.startAccStreaming(identifier, settings).subscribe({
            invokeOnUiThread("accDataReceived", listOf(identifier, gson.toJson(it)))
        }, { Log.e(tag, it.localizedMessage ?: "Unknown accStreaming error") }).discard()
    }

    private fun startGyroStreaming(identifier: String, settings: PolarSensorSetting) {
        api.startGyroStreaming(identifier, settings).subscribe({
            invokeOnUiThread("gyroDataReceived", listOf(identifier, gson.toJson(it)))
        }, { Log.e(tag, it.localizedMessage ?: "Unknown gyroStreaming error") }).discard()
    }

    private fun startMagnetometerStreaming(identifier: String, settings: PolarSensorSetting) {
        api.startMagnetometerStreaming(identifier, settings).subscribe({
            invokeOnUiThread("magnetometerDataReceived", listOf(identifier, gson.toJson(it)))
        }, { Log.e(tag, it.localizedMessage ?: "Unknown magnetometerStreaming error") }).discard()
    }

    private fun startOhrStreaming(identifier: String, settings: PolarSensorSetting) {
        api.startOhrStreaming(identifier, settings).subscribe({
            invokeOnUiThread("ohrDataReceived", listOf(identifier, gson.toJson(it)))
        }, { Log.e(tag, it.localizedMessage ?: "Unknown ohrStreaming error") }).discard()
    }

    private fun startOhrPPIStreaming(identifier: String) {
        api.startOhrPPIStreaming(identifier).subscribe({
            invokeOnUiThread("ohrPPIReceived", listOf(identifier, gson.toJson(it)))
        }, { Log.e(tag, it.localizedMessage ?: "Unknown ohrPPIStreaming error") }).discard()
    }

    override fun blePowerStateChanged(powered: Boolean) {
        invokeOnUiThread("blePowerStateChanged", powered)
    }

    override fun deviceConnected(info: PolarDeviceInfo) {
        invokeOnUiThread("deviceConnected", gson.toJson(info))
    }

    override fun deviceConnecting(info: PolarDeviceInfo) {
        invokeOnUiThread("deviceConnecting", gson.toJson(info))
    }

    override fun deviceDisconnected(info: PolarDeviceInfo) {
        invokeOnUiThread("deviceDisconnected", gson.toJson(info))
    }

    override fun streamingFeaturesReady(
        identifier: String,
        features: MutableSet<PolarBleApi.DeviceStreamingFeature>
    ) {
        invokeOnUiThread("streamingFeaturesReady", listOf(identifier, gson.toJson(features)))
    }

    override fun sdkModeFeatureAvailable(identifier: String) {
        invokeOnUiThread("sdkModeFeatureAvailable", identifier)
    }

    override fun hrFeatureReady(identifier: String) {
        invokeOnUiThread("hrFeatureReady", identifier)
    }

    override fun disInformationReceived(identifier: String, uuid: UUID, value: String) {
        invokeOnUiThread("disInformationReceived", listOf(identifier, uuid.toString(), value))
    }

    override fun batteryLevelReceived(identifier: String, level: Int) {
        invokeOnUiThread("batteryLevelReceived", listOf(identifier, level))
    }

    override fun hrNotificationReceived(identifier: String, data: PolarHrData) {
        invokeOnUiThread("hrNotificationReceived", listOf(identifier, gson.toJson(data)))
    }

    override fun polarFtpFeatureReady(identifier: String) {
        invokeOnUiThread("polarFtpFeatureReady", identifier)
    }
}
