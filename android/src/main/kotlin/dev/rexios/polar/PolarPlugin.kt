package dev.rexios.polar

import android.os.Handler
import android.os.Looper
import androidx.lifecycle.Lifecycle.Event
import androidx.lifecycle.LifecycleEventObserver
import com.google.gson.GsonBuilder
import com.google.gson.JsonDeserializationContext
import com.google.gson.JsonDeserializer
import com.google.gson.JsonElement
import com.google.gson.JsonPrimitive
import com.google.gson.JsonSerializationContext
import com.google.gson.JsonSerializer
import com.polar.sdk.api.PolarBleApi
import com.polar.sdk.api.PolarBleApi.DeviceStreamingFeature
import com.polar.sdk.api.PolarBleApiCallbackProvider
import com.polar.sdk.api.PolarBleApiDefaultImpl
import com.polar.sdk.api.model.PolarDeviceInfo
import com.polar.sdk.api.model.PolarExerciseEntry
import com.polar.sdk.api.model.PolarHrData
import com.polar.sdk.api.model.PolarSensorSetting
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.embedding.engine.plugins.lifecycle.FlutterLifecycleAdapter
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.reactivex.rxjava3.disposables.Disposable
import java.lang.reflect.Type
import java.util.Date
import java.util.UUID

fun Any?.discard() = Unit

object DateSerializer : JsonDeserializer<Date>, JsonSerializer<Date> {
    override fun deserialize(
        json: JsonElement?, typeOfT: Type?, context: JsonDeserializationContext?
    ): Date {
        return Date(json?.asJsonPrimitive?.asLong ?: 0)
    }

    override fun serialize(
        src: Date?, typeOfSrc: Type?, context: JsonSerializationContext?
    ): JsonElement {
        return JsonPrimitive(src?.time)
    }
}

private fun runOnUiThread(runnable: () -> Unit) {
    Handler(Looper.getMainLooper()).post { runnable() }
}

private val gson = GsonBuilder().registerTypeAdapter(Date::class.java, DateSerializer).create()

/** PolarPlugin */
class PolarPlugin : FlutterPlugin, MethodCallHandler, PolarBleApiCallbackProvider, ActivityAware {
    /// Binary messenger for dynamic EventChannel registration
    private lateinit var messenger: BinaryMessenger

    /// Method channel
    private lateinit var channel: MethodChannel

    /// Search channel
    private lateinit var searchChannel: EventChannel

    /// Streaming channels
    private val streamingChannels = mutableMapOf<String, StreamingChannel>()

    private lateinit var api: PolarBleApi

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        messenger = flutterPluginBinding.binaryMessenger

        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "polar")
        channel.setMethodCallHandler(this)

        searchChannel = EventChannel(flutterPluginBinding.binaryMessenger, "polar/search")
        searchChannel.setStreamHandler(searchHandler)

        api = PolarBleApiDefaultImpl.defaultImplementation(
            flutterPluginBinding.applicationContext, PolarBleApi.ALL_FEATURES
        )
        api.setApiCallback(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        searchChannel.setStreamHandler(null)
        streamingChannels.values.forEach { it.dispose() }
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

            "requestStreamSettings" -> requestStreamSettings(call, result)
            "createStreamingChannel" -> createStreamingChannel(call, result)
            "startRecording" -> startRecording(call, result)
            "stopRecording" -> stopRecording(call, result)
            "requestRecordingStatus" -> requestRecordingStatus(call, result)
            "listExercises" -> listExercises(call, result)
            "fetchExercise" -> fetchExercise(call, result)
            "removeExercise" -> removeExercise(call, result)
            else -> result.notImplemented()
        }
    }

    private val searchHandler = object : EventChannel.StreamHandler {
        private var searchSubscription: Disposable? = null

        override fun onListen(arguments: Any?, events: EventSink) {
            searchSubscription = api.searchForDevice().subscribe({
                runOnUiThread { events.success(gson.toJson(it)) }
            }, {
                runOnUiThread {
                    events.error(it.toString(), it.message, null)
                }
            }, {
                runOnUiThread { events.endOfStream() }
            })
        }

        override fun onCancel(arguments: Any) {
            searchSubscription?.dispose()
        }
    }

    private fun createStreamingChannel(call: MethodCall, result: Result) {
        val arguments = call.arguments as List<*>
        val name = arguments[0] as String
        val identifier = arguments[1] as String
        val feature = gson.fromJson(arguments[2] as String, DeviceStreamingFeature::class.java)

        if (streamingChannels[name] == null) {
            streamingChannels[name] = StreamingChannel(messenger, name, api, identifier, feature)
        }

        result.success(null)
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

    private fun shutdown() {
        try {
            api.shutDown()
        } catch (e: Exception) {
            // This will throw if the api is already shut down
        }
    }

    private fun requestStreamSettings(call: MethodCall, result: Result) {
        val arguments = call.arguments as List<*>
        val identifier = arguments[0] as String
        val feature = gson.fromJson(arguments[1] as String, DeviceStreamingFeature::class.java)

        api.requestStreamSettings(identifier, feature).subscribe({
            runOnUiThread { result.success(gson.toJson(it)) }
        }, {
            runOnUiThread {
                result.error(it.toString(), it.message, null)
            }
        }).discard()
    }

    private fun startRecording(call: MethodCall, result: Result) {
        val arguments = call.arguments as List<*>
        val identifier = arguments[0] as String
        val exerciseId = arguments[1] as String
        val interval =
            gson.fromJson(arguments[2] as String, PolarBleApi.RecordingInterval::class.java)
        val sampleType = gson.fromJson(arguments[3] as String, PolarBleApi.SampleType::class.java)

        api.startRecording(identifier, exerciseId, interval, sampleType).subscribe({
            runOnUiThread { result.success(null) }
        }, {
            runOnUiThread {
                result.error(it.toString(), it.message, null)
            }
        }).discard()
    }

    private fun stopRecording(call: MethodCall, result: Result) {
        val identifier = call.arguments as String

        api.stopRecording(identifier).subscribe({
            runOnUiThread { result.success(null) }
        }, {
            runOnUiThread {
                result.error(it.toString(), it.message, null)
            }
        }).discard()
    }

    private fun requestRecordingStatus(call: MethodCall, result: Result) {
        val identifier = call.arguments as String

        api.requestRecordingStatus(identifier).subscribe({
            runOnUiThread { result.success(listOf(it.first, it.second)) }
        }, {
            runOnUiThread {
                result.error(it.toString(), it.message, null)
            }
        }).discard()
    }

    private fun listExercises(call: MethodCall, result: Result) {
        val identifier = call.arguments as String

        val exercises = mutableListOf<String>()
        api.listExercises(identifier).subscribe({
            exercises.add(gson.toJson(it))
        }, {
            runOnUiThread {
                result.error(it.toString(), it.message, null)
            }
        }, {
            result.success(exercises)
        }).discard()
    }

    private fun fetchExercise(call: MethodCall, result: Result) {
        val arguments = call.arguments as List<*>
        val identifier = arguments[0] as String
        val entry = gson.fromJson(arguments[1] as String, PolarExerciseEntry::class.java)

        api.fetchExercise(identifier, entry).subscribe({
            result.success(gson.toJson(it))
        }, {
            runOnUiThread {
                result.error(it.toString(), it.message, null)
            }
        }).discard()
    }

    private fun removeExercise(call: MethodCall, result: Result) {
        val arguments = call.arguments as List<*>
        val identifier = arguments[0] as String
        val entry = gson.fromJson(arguments[1] as String, PolarExerciseEntry::class.java)

        api.removeExercise(identifier, entry).subscribe({
            runOnUiThread { result.success(null) }
        }, {
            runOnUiThread {
                result.error(it.toString(), it.message, null)
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
        identifier: String, features: MutableSet<DeviceStreamingFeature>
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
        invokeOnUiThread("ftpFeatureReady", identifier)
    }
}

class StreamingChannel(
    messenger: BinaryMessenger,
    name: String,
    private val api: PolarBleApi,
    private val identifier: String,
    private val feature: DeviceStreamingFeature,
    private val channel: EventChannel = EventChannel(messenger, name)
) : EventChannel.StreamHandler {
    private var subscription: Disposable? = null

    init {
        channel.setStreamHandler(this)
    }

    override fun onListen(arguments: Any?, events: EventSink) {
        arguments as List<*>
        // Will be null for ppi feature
        val settings = gson.fromJson(arguments[0] as String, PolarSensorSetting::class.java)

        val stream = when (feature) {
            DeviceStreamingFeature.ECG -> api.startEcgStreaming(identifier, settings)
            DeviceStreamingFeature.ACC -> api.startAccStreaming(identifier, settings)
            DeviceStreamingFeature.GYRO -> api.startGyroStreaming(identifier, settings)
            DeviceStreamingFeature.MAGNETOMETER -> api.startMagnetometerStreaming(
                identifier, settings
            )

            DeviceStreamingFeature.PPG -> api.startOhrStreaming(identifier, settings)
            DeviceStreamingFeature.PPI -> api.startOhrPPIStreaming(identifier)
            else -> throw Exception("Unknown streaming feature $feature")
        }

        subscription = stream.subscribe({
            runOnUiThread { events.success(gson.toJson(it)) }
        }, {
            runOnUiThread {
                events.error(it.toString(), it.message, null)
            }
        }, {
            runOnUiThread { events.endOfStream() }
        })
    }

    override fun onCancel(arguments: Any?) {
        subscription?.dispose()
    }

    fun dispose() {
        subscription?.dispose()
        channel.setStreamHandler(null)
    }
}