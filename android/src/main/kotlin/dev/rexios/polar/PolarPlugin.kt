package dev.rexios.polar

import android.os.Handler
import android.os.Looper
import androidx.lifecycle.Lifecycle.Event
import androidx.lifecycle.LifecycleEventObserver
import com.google.gson.Gson
import com.polar.sdk.api.PolarBleApi
import com.polar.sdk.api.PolarBleApi.DeviceStreamingFeature
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
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.reactivex.rxjava3.disposables.Disposable
import java.util.*

fun Any?.discard() = Unit

/** PolarPlugin */
class PolarPlugin : FlutterPlugin, MethodCallHandler, PolarBleApiCallbackProvider, ActivityAware, {
    private val tag = "Polar"
    private lateinit var channel: MethodChannel
    private lateinit var searchChannel: EventChannel
    private lateinit var streamingChannel: EventChannel
    private lateinit var api: PolarBleApi

    private val gson = Gson()

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "polar")
        channel.setMethodCallHandler(this)

        searchChannel = EventChannel(flutterPluginBinding.binaryMessenger, "polar/search")
        searchChannel.setStreamHandler(searchHandler)

        streamingChannel = EventChannel(flutterPluginBinding.binaryMessenger, "polar/streaming")
        streamingChannel.setStreamHandler(streamingHandler)

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

            else -> result.notImplemented()
        }
    }

    private val searchHandler = object : EventChannel.StreamHandler {
        private var searchSubscription: Disposable? = null

        override fun onListen(arguments: Any?, events: EventSink) {
            searchSubscription = api.searchForDevice().subscribe({
                events.success(gson.toJson(it))
            }, {
                events.error(
                    it.localizedMessage ?: "Unknown error searching for device",
                    null,
                    null
                )
            }, {
                events.endOfStream()
            })
        }

        override fun onCancel(arguments: Any) {
            searchSubscription?.dispose()
        }
    }

    private val streamingHandler = object : EventChannel.StreamHandler {
        // Map of <feature, <identifier, subscription>>
        private val subs = mutableMapOf<DeviceStreamingFeature, MutableMap<String, Disposable>>()

        override fun onListen(arguments: Any?, events: EventSink) {
            arguments as List<*>
            val feature = gson.fromJson(arguments[0] as String, DeviceStreamingFeature::class.java)
            val identifier = arguments[1] as String
            val settings = gson.fromJson(arguments[2] as String, PolarSensorSetting::class.java)

            if (subs[feature] == null) {
                subs[feature] = mutableMapOf()
            }

            subs[feature]!![identifier] = when (feature) {
                DeviceStreamingFeature.ECG -> api.startEcgStreaming(identifier, settings)
                    .subscribe({
                        events.success(gson.toJson(it))
                    }, {
                        events.error(
                            it.localizedMessage ?: "Unknown error streaming ECG",
                            null,
                            null
                        )
                    }, {
                        events.endOfStream()
                    })

                DeviceStreamingFeature.ACC -> api.startAccStreaming(identifier, settings)
                    .subscribe({
                        events.success(gson.toJson(it))
                    }, {
                        events.error(
                            it.localizedMessage ?: "Unknown error streaming ACC",
                            null,
                            null
                        )
                    }, {
                        events.endOfStream()
                    })

                DeviceStreamingFeature.GYRO -> api.startGyroStreaming(identifier, settings)
                    .subscribe({
                        events.success(gson.toJson(it))
                    }, {
                        events.error(
                            it.localizedMessage ?: "Unknown error streaming GYRO",
                            null,
                            null
                        )
                    }, {
                        events.endOfStream()
                    })

                DeviceStreamingFeature.MAGNETOMETER -> api.startMagnetometerStreaming(
                    identifier,
                    settings
                ).subscribe({
                    events.success(gson.toJson(it))
                }, {
                    events.error(
                        it.localizedMessage ?: "Unknown error streaming MAGNETOMETER",
                        null,
                        null
                    )
                }, {
                    events.endOfStream()
                })

                DeviceStreamingFeature.PPG -> api.startOhrStreaming(identifier, settings)
                    .subscribe({
                        events.success(gson.toJson(it))
                    }, {
                        events.error(
                            it.localizedMessage ?: "Unknown error streaming OHR",
                            null,
                            null
                        )
                    }, {
                        events.endOfStream()
                    })

                DeviceStreamingFeature.PPI -> api.startOhrPPIStreaming(identifier).subscribe({
                    events.success(gson.toJson(it))
                }, {
                    events.error(
                        it.localizedMessage ?: "Unknown error streaming OHR PPI",
                        null,
                        null
                    )
                }, {
                    events.endOfStream()
                })

                else -> throw Exception("Unknown streaming feature $feature")
            }


        }

        override fun onCancel(arguments: Any) {
            arguments as List<*>
            val feature = gson.fromJson(arguments[0] as String, DeviceStreamingFeature::class.java)
            val identifier = arguments[1] as String

            subs[feature]?.get(identifier)?.dispose()
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
