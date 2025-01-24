package dev.rexios.polar

import android.content.Context
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
import com.polar.androidcommunications.api.ble.model.DisInfo
import com.polar.sdk.api.PolarBleApi
import com.polar.sdk.api.PolarBleApi.PolarBleSdkFeature
import com.polar.sdk.api.PolarBleApi.PolarDeviceDataType
import com.polar.sdk.api.PolarBleApiCallbackProvider
import com.polar.sdk.api.PolarBleApiDefaultImpl
import com.polar.sdk.api.PolarH10OfflineExerciseApi.RecordingInterval
import com.polar.sdk.api.PolarH10OfflineExerciseApi.SampleType
import com.polar.sdk.api.model.LedConfig
import com.polar.sdk.api.model.PolarDeviceInfo
import com.polar.sdk.api.model.PolarExerciseEntry
import com.polar.sdk.api.model.PolarFirstTimeUseConfig
import com.polar.sdk.api.model.PolarHrData
import com.polar.sdk.api.model.PolarSensorSetting
import com.polar.sdk.api.model.PolarOfflineRecordingEntry
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
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.UUID

fun Any?.discard() = Unit

object DateSerializer : JsonDeserializer<Date>, JsonSerializer<Date> {
    override fun deserialize(
        json: JsonElement?,
        typeOfT: Type?,
        context: JsonDeserializationContext?,
    ): Date = Date(json?.asJsonPrimitive?.asLong ?: 0)

    override fun serialize(
        src: Date?,
        typeOfSrc: Type?,
        context: JsonSerializationContext?,
    ): JsonElement = JsonPrimitive(src?.time)
}

private fun runOnUiThread(runnable: () -> Unit) {
    Handler(Looper.getMainLooper()).post { runnable() }
}

private val gson = GsonBuilder().registerTypeAdapter(Date::class.java, DateSerializer).create()

private var wrapperInternal: PolarWrapper? = null
private val wrapper: PolarWrapper
    get() = wrapperInternal!!

/** PolarPlugin */
class PolarPlugin :
    FlutterPlugin,
    MethodCallHandler,
    ActivityAware {
    // Binary messenger for dynamic EventChannel registration
    private lateinit var messenger: BinaryMessenger

    // Method channel
    private lateinit var channel: MethodChannel

    // Search channel
    private lateinit var searchChannel: EventChannel

    // Context
    private lateinit var context: Context

    // Streaming channels
    private val streamingChannels = mutableMapOf<String, StreamingChannel>()

    // Apparently you have to call invokeMethod on the UI thread
    private fun invokeOnUiThread(
        method: String,
        arguments: Any?,
        callback: Result? = null,
    ) {
        runOnUiThread { channel.invokeMethod(method, arguments, callback) }
    }

    private val polarCallback = { method: String, arguments: Any? ->
        invokeOnUiThread(method, arguments)
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        messenger = flutterPluginBinding.binaryMessenger

        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "polar")
        channel.setMethodCallHandler(this)

        searchChannel = EventChannel(flutterPluginBinding.binaryMessenger, "polar/search")
        searchChannel.setStreamHandler(searchHandler)

        context = flutterPluginBinding.applicationContext
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        searchChannel.setStreamHandler(null)
        streamingChannels.values.forEach { it.dispose() }
        shutDown()
    }

    private fun initApi() {
        if (wrapperInternal == null) {
            wrapperInternal = PolarWrapper(context)
        }
        wrapper.addCallback(polarCallback)
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result,
    ) {
        initApi()

        when (call.method) {
            "connectToDevice" -> {
                wrapper.api.connectToDevice(call.arguments as String)
                result.success(null)
            }

            "disconnectFromDevice" -> {
                wrapper.api.disconnectFromDevice(call.arguments as String)
                result.success(null)
            }

            "getAvailableOnlineStreamDataTypes" -> getAvailableOnlineStreamDataTypes(call, result)
            "requestStreamSettings" -> requestStreamSettings(call, result)
            "createStreamingChannel" -> createStreamingChannel(call, result)
            "startRecording" -> startRecording(call, result)
            "stopRecording" -> stopRecording(call, result)
            "requestRecordingStatus" -> requestRecordingStatus(call, result)
            "listExercises" -> listExercises(call, result)
            "fetchExercise" -> fetchExercise(call, result)
            "removeExercise" -> removeExercise(call, result)
            "setLedConfig" -> setLedConfig(call, result)
            "doFactoryReset" -> doFactoryReset(call, result)
            "enableSdkMode" -> enableSdkMode(call, result)
            "disableSdkMode" -> disableSdkMode(call, result)
            "isSdkModeEnabled" -> isSdkModeEnabled(call, result)
            "getAvailableOfflineRecordingDataTypes" -> getAvailableOfflineRecordingDataTypes(call, result)
            "requestOfflineRecordingSettings" -> requestOfflineRecordingSettings(call, result)
            "startOfflineRecording" -> startOfflineRecording(call, result)
            "stopOfflineRecording" -> stopOfflineRecording(call, result)
            "getOfflineRecordingStatus" -> getOfflineRecordingStatus(call, result)
            "listOfflineRecordings" -> listOfflineRecordings(call, result)
            "getOfflineRecord" -> getOfflineRecord(call, result)
            "removeOfflineRecord" -> removeOfflineRecord(call, result)
            "getDiskSpace" -> getDiskSpace(call, result)
            "getLocalTime" -> getLocalTime(call, result)
            "setLocalTime" -> setLocalTime(call, result)
            "doFirstTimeUse" -> doFirstTimeUse(call, result)

            else -> result.notImplemented()
        }
    }

    private val searchHandler =
        object : EventChannel.StreamHandler {
            private var searchSubscription: Disposable? = null

            override fun onListen(
                arguments: Any?,
                events: EventSink,
            ) {
                initApi()

                searchSubscription =
                    wrapper.api.searchForDevice().subscribe({
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
                searchSubscription?.dispose()
            }
        }

    private fun createStreamingChannel(
        call: MethodCall,
        result: Result,
    ) {
        val arguments = call.arguments as List<*>
        val name = arguments[0] as String
        val identifier = arguments[1] as String
        val feature = gson.fromJson(arguments[2] as String, PolarDeviceDataType::class.java)

        if (streamingChannels[name] == null) {
            streamingChannels[name] =
                StreamingChannel(messenger, name, wrapper.api, identifier, feature)
        }

        result.success(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        val lifecycle = FlutterLifecycleAdapter.getActivityLifecycle(binding)
        lifecycle.addObserver(
            LifecycleEventObserver { _, event ->
                when (event) {
                    Event.ON_RESUME -> wrapperInternal?.api?.foregroundEntered()
                    Event.ON_DESTROY -> shutDown()
                    else -> {}
                }
            },
        )
    }

    override fun onDetachedFromActivityForConfigChanges() {}

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {}

    override fun onDetachedFromActivity() {}

    private fun shutDown() {
        if (wrapperInternal == null) return
        wrapper.removeCallback(polarCallback)
        wrapper.shutDown()
    }

    private fun getAvailableOnlineStreamDataTypes(
        call: MethodCall,
        result: Result,
    ) {
        val identifier = call.arguments as String

        wrapper.api
            .getAvailableOnlineStreamDataTypes(identifier)
            .subscribe({
                runOnUiThread { result.success(gson.toJson(it)) }
            }, {
                runOnUiThread {
                    result.error(it.toString(), it.message, null)
                }
            })
            .discard()
    }

    private fun requestStreamSettings(
        call: MethodCall,
        result: Result,
    ) {
        val arguments = call.arguments as List<*>
        val identifier = arguments[0] as String
        val feature = gson.fromJson(arguments[1] as String, PolarDeviceDataType::class.java)

        wrapper.api
            .requestStreamSettings(identifier, feature)
            .subscribe({
                runOnUiThread { result.success(gson.toJson(it)) }
            }, {
                runOnUiThread {
                    result.error(it.toString(), it.message, null)
                }
            })
            .discard()
    }

    private fun startRecording(
        call: MethodCall,
        result: Result,
    ) {
        val arguments = call.arguments as List<*>
        val identifier = arguments[0] as String
        val exerciseId = arguments[1] as String
        val interval = gson.fromJson(arguments[2] as String, RecordingInterval::class.java)
        val sampleType = gson.fromJson(arguments[3] as String, SampleType::class.java)

        wrapper.api
            .startRecording(identifier, exerciseId, interval, sampleType)
            .subscribe({
                runOnUiThread { result.success(null) }
            }, {
                runOnUiThread {
                    result.error(it.toString(), it.message, null)
                }
            })
            .discard()
    }

    private fun stopRecording(
        call: MethodCall,
        result: Result,
    ) {
        val identifier = call.arguments as String

        wrapper.api
            .stopRecording(identifier)
            .subscribe({
                runOnUiThread { result.success(null) }
            }, {
                runOnUiThread {
                    result.error(it.toString(), it.message, null)
                }
            })
            .discard()
    }

    private fun requestRecordingStatus(
        call: MethodCall,
        result: Result,
    ) {
        val identifier = call.arguments as String

        wrapper.api
            .requestRecordingStatus(identifier)
            .subscribe({
                runOnUiThread { result.success(listOf(it.first, it.second)) }
            }, {
                runOnUiThread {
                    result.error(it.toString(), it.message, null)
                }
            })
            .discard()
    }

    private fun listExercises(
        call: MethodCall,
        result: Result,
    ) {
        val identifier = call.arguments as String

        val exercises = mutableListOf<String>()
        wrapper.api
            .listExercises(identifier)
            .subscribe({
                exercises.add(gson.toJson(it))
            }, {
                runOnUiThread {
                    result.error(it.toString(), it.message, null)
                }
            }, {
                result.success(exercises)
            })
            .discard()
    }

    private fun fetchExercise(
        call: MethodCall,
        result: Result,
    ) {
        val arguments = call.arguments as List<*>
        val identifier = arguments[0] as String
        val entry = gson.fromJson(arguments[1] as String, PolarExerciseEntry::class.java)

        wrapper.api
            .fetchExercise(identifier, entry)
            .subscribe({
                result.success(gson.toJson(it))
            }, {
                runOnUiThread {
                    result.error(it.toString(), it.message, null)
                }
            })
            .discard()
    }

    private fun removeExercise(
        call: MethodCall,
        result: Result,
    ) {
        val arguments = call.arguments as List<*>
        val identifier = arguments[0] as String
        val entry = gson.fromJson(arguments[1] as String, PolarExerciseEntry::class.java)

        wrapper.api
            .removeExercise(identifier, entry)
            .subscribe({
                runOnUiThread { result.success(null) }
            }, {
                runOnUiThread {
                    result.error(it.toString(), it.message, null)
                }
            })
            .discard()
    }

    private fun setLedConfig(
        call: MethodCall,
        result: Result,
    ) {
        val arguments = call.arguments as List<*>
        val identifier = arguments[0] as String
        val config = gson.fromJson(arguments[1] as String, LedConfig::class.java)

        wrapper.api
            .setLedConfig(identifier, config)
            .subscribe({
                runOnUiThread { result.success(null) }
            }, {
                runOnUiThread {
                    result.error(it.toString(), it.message, null)
                }
            })
            .discard()
    }

    private fun doFactoryReset(
        call: MethodCall,
        result: Result,
    ) {
        val arguments = call.arguments as List<*>
        val identifier = arguments[0] as String
        val preservePairingInformation = arguments[1] as Boolean

        wrapper.api
            .doFactoryReset(identifier, preservePairingInformation)
            .subscribe({
                runOnUiThread { result.success(null) }
            }, {
                runOnUiThread {
                    result.error(it.toString(), it.message, null)
                }
            })
            .discard()
    }

    private fun enableSdkMode(
        call: MethodCall,
        result: Result,
    ) {
        val identifier = call.arguments as String
        wrapper.api
            .enableSDKMode(identifier)
            .subscribe({
                runOnUiThread { result.success(null) }
            }, {
                runOnUiThread {
                    result.error(it.toString(), it.message, null)
                }
            })
            .discard()
    }

    private fun disableSdkMode(
        call: MethodCall,
        result: Result,
    ) {
        val identifier = call.arguments as String
        wrapper.api
            .disableSDKMode(identifier)
            .subscribe({
                runOnUiThread { result.success(null) }
            }, {
                runOnUiThread {
                    result.error(it.toString(), it.message, null)
                }
            })
            .discard()
    }

    private fun isSdkModeEnabled(
        call: MethodCall,
        result: Result,
    ) {
        val identifier = call.arguments as String
        wrapper.api
            .isSDKModeEnabled(identifier)
            .subscribe({
                runOnUiThread { result.success(it) }
            }, {
                runOnUiThread {
                    result.error(it.toString(), it.message, null)
                }
            })
            .discard()
    }

    private fun getAvailableOfflineRecordingDataTypes(call: MethodCall, result: Result) {
        val identifier = call.arguments as String

        wrapper.api
            .getAvailableOfflineRecordingDataTypes(identifier)
            .subscribe({
                runOnUiThread { result.success(gson.toJson(it)) }
            }, {
                runOnUiThread {
                    result.error(it.toString(), it.message, null)
                }
            })
            .discard()
    }

    private fun requestOfflineRecordingSettings(call: MethodCall, result: Result) {
        val arguments = call.arguments as List<*>
        val identifier = arguments[0] as String
        val feature = gson.fromJson(arguments[1] as String, PolarDeviceDataType::class.java)

        wrapper.api
            .requestOfflineRecordingSettings(identifier, feature)
            .subscribe({
                runOnUiThread { result.success(gson.toJson(it)) }
            }, {
                runOnUiThread {
                    result.error(it.toString(), it.message, null)
                }
            })
            .discard()
    }

    private fun startOfflineRecording(call: MethodCall, result: Result) {
        val arguments = call.arguments as List<*>
        val identifier = arguments[0] as String
        val feature = gson.fromJson(arguments[1] as String, PolarDeviceDataType::class.java)
        val settings = gson.fromJson(arguments[2] as String, PolarSensorSetting::class.java)

        wrapper.api
            .startOfflineRecording(identifier, feature, settings)
            .subscribe({
                runOnUiThread { result.success(null) }
            }, {
                runOnUiThread {
                    result.error("ERROR_STARTING_RECORDING", it.message, null)
                }
            })
            .discard()
    }

    private fun stopOfflineRecording(call: MethodCall, result: Result) {
        val arguments = call.arguments as List<*>
        val identifier = arguments[0] as String
        val feature = gson.fromJson(arguments[1] as String, PolarDeviceDataType::class.java)

        wrapper.api
            .stopOfflineRecording(identifier, feature)
            .subscribe({
                runOnUiThread { result.success(null) }
            }, {
                runOnUiThread {
                    result.error("ERROR_STOPPING_RECORDING", it.message, null)
                }
            })
            .discard()
    }

    private fun getOfflineRecordingStatus(call: MethodCall, result: Result) {
        val arguments = call.arguments as List<*>
        val identifier = arguments[0] as String

        wrapper.api
            .getOfflineRecordingStatus(identifier)
            .subscribe({ dataTypes ->
                val dataTypeNames = dataTypes.map { it.name }
                runOnUiThread { result.success(dataTypeNames) }
            }, {
                runOnUiThread {
                    result.error(it.toString(), it.message, null)
                }
            })
            .discard()
    }

    private fun listOfflineRecordings(call: MethodCall, result: Result) {
        val identifier = call.arguments as String

        val recordings = mutableListOf<String>()
        wrapper.api
            .listOfflineRecordings(identifier)
            .subscribe({
                recordings.add(gson.toJson(it))
            }, {
                runOnUiThread {
                    result.error(it.toString(), it.message, null)
                }
            }, {
                result.success(recordings)
            })
            .discard()
    }

    private fun getOfflineRecord(call: MethodCall, result: Result) {
        val arguments = call.arguments as List<*>
        val identifier = arguments[0] as String
        val entry = gson.fromJson(arguments[1] as String, PolarOfflineRecordingEntry::class.java)

        wrapper.api
            .getOfflineRecord(identifier, entry)
            .subscribe({
                runOnUiThread { result.success(gson.toJson(it)) }
            }, {
                runOnUiThread {
                    result.error(it.toString(), it.message, null)
                }
            })
            .discard()
    }

    private fun removeOfflineRecord(call: MethodCall, result: Result) {
        val arguments = call.arguments as List<*>
        val identifier = arguments[0] as String
        val entry = gson.fromJson(arguments[1] as String, PolarOfflineRecordingEntry::class.java)

        wrapper.api
            .removeOfflineRecord(identifier, entry)
            .subscribe({
                runOnUiThread { result.success(null) }
            }, {
                runOnUiThread {
                    result.error(it.toString(), it.message, null)
                }
            })
            .discard()
    }

    private fun getDiskSpace(call: MethodCall, result: Result) {
        val identifier = call.arguments as String

        wrapper.api
            .getDiskSpace(identifier)
            .subscribe({
                val (availableSpace, freeSpace) = it
                runOnUiThread {
                    result.success(listOf(availableSpace, freeSpace))
                }
            }, {
                runOnUiThread {
                    result.error(it.toString(), it.message, null)
                }
            })
            .discard()
    }

    private fun getLocalTime(call: MethodCall, result: Result) {
        val identifier = call.arguments as? String ?: run {
            result.error("ERROR_INVALID_ARGUMENT", "Expected a single String argument", null)
            return
        }

        wrapper.api
            .getLocalTime(identifier)
            .subscribe({ deviceTime ->
                try {
                    // Format the device time using SimpleDateFormat
                    val dateFormat = java.text.SimpleDateFormat(
                        "yyyy-MM-dd'T'HH:mm:ssXXX",
                        java.util.Locale.getDefault()
                    )
                    dateFormat.timeZone = deviceTime.timeZone
                    val timeString = dateFormat.format(deviceTime.time)

                    // Return the formatted date as a string
                    runOnUiThread {
                        result.success(timeString)
                    }
                } catch (e: Exception) {
                    runOnUiThread {
                        result.error("ERROR_FORMATTING_TIME", e.message, null)
                    }
                }
            }, {
                runOnUiThread {
                    result.error(it.toString(), it.message, null)
                }
            })
            .discard()
    }

    private fun setLocalTime(call: MethodCall, result: Result) {
        val arguments = call.arguments as List<*>
        val identifier = arguments[0] as String
        val timestamp = arguments[1] as Double

        // Convert the timestamp to a Date object
        val date =
            java.util.Date((timestamp * 1000).toLong()) // Multiply by 1000 to convert seconds to milliseconds

        // Convert Date to Calendar
        val calendar = java.util.Calendar.getInstance()
        calendar.time = date

        // Now, call the API with Calendar
        wrapper.api
            .setLocalTime(identifier, calendar)
            .subscribe({
                runOnUiThread { result.success(null) }
            }, {
                runOnUiThread {
                    result.error(it.toString(), it.message, null)
                }
            })
            .discard()
    }

    private fun doFirstTimeUse(call: MethodCall, result: Result) {
        val arguments = call.arguments as Map<*, *>
        val identifier = arguments["identifier"] as? String
        val configMap = arguments["config"] as? Map<*, *>

        if (identifier == null || configMap == null) {
            result.error(
                "INVALID_ARGUMENTS",
                "Expected identifier and config map",
                null
            )
            return
        }
        // Extract configuration values
        val gender = configMap["gender"] as? String
        val birthDateString = configMap["birthDate"] as? String
        val height = (configMap["height"] as? Int)?.toFloat()
        val weight = (configMap["weight"] as? Int)?.toFloat()
        val maxHeartRate = configMap["maxHeartRate"] as? Int
        val vo2Max = configMap["vo2Max"] as? Int
        val restingHeartRate = configMap["restingHeartRate"] as? Int
        val trainingBackground = configMap["trainingBackground"] as? Int
        val deviceTime = configMap["deviceTime"] as? String
        val typicalDay = configMap["typicalDay"] as? Int
        val sleepGoalMinutes = configMap["sleepGoalMinutes"] as? Int

        // Validate required parameters
        if (gender == null || birthDateString == null || height == null || weight == null ||
            maxHeartRate == null || vo2Max == null || restingHeartRate == null ||
            trainingBackground == null || deviceTime == null || typicalDay == null ||
            sleepGoalMinutes == null
        ) {
            result.error(
                "INVALID_CONFIG",
                "Invalid configuration parameters",
                null
            )
            return
        }

        // Parse birth date
        val birthDate = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).parse(birthDateString)

        // Map gender string to PolarFirstTimeUseConfig.Gender enum
        val genderEnum = when (gender) {
            "Male" -> PolarFirstTimeUseConfig.Gender.MALE
            "Female" -> PolarFirstTimeUseConfig.Gender.FEMALE
            else -> throw IllegalArgumentException("Invalid gender value")
        }

        // Map typicalDay to PolarFirstTimeUseConfig.TypicalDay enum
        val typicalDayEnum = when (typicalDay) {
            1 -> PolarFirstTimeUseConfig.TypicalDay.MOSTLY_MOVING
            2 -> PolarFirstTimeUseConfig.TypicalDay.MOSTLY_SITTING
            3 -> PolarFirstTimeUseConfig.TypicalDay.MOSTLY_STANDING
            else -> PolarFirstTimeUseConfig.TypicalDay.MOSTLY_SITTING // Default
        }

        // Create PolarFirstTimeUseConfig instance
        val ftuConfig = PolarFirstTimeUseConfig(
            genderEnum,
            birthDate,
            height,
            weight,
            maxHeartRate,
            vo2Max,
            restingHeartRate,
            trainingBackground,
            deviceTime,
            typicalDayEnum,
            sleepGoalMinutes
        )

        // Call the Polar API
        wrapper.api
            .doFirstTimeUse(identifier, ftuConfig)
            .subscribe({
                runOnUiThread { result.success(null) }
            }, {
                runOnUiThread {
                    result.error(it.toString(), it.message, null)
                }
            })
            .discard()
    }

}

class PolarWrapper(
    context: Context,
    val api: PolarBleApi =
        PolarBleApiDefaultImpl.defaultImplementation(
            context,
            PolarBleSdkFeature.entries.toSet(),
        ),
    private val callbacks: MutableSet<(String, Any?) -> Unit> = mutableSetOf(),
) : PolarBleApiCallbackProvider {
    init {
        api.setApiCallback(this)
    }

    fun addCallback(callback: (String, Any?) -> Unit) {
        if (callbacks.contains(callback)) return
        callbacks.add(callback)
    }

    fun removeCallback(callback: (String, Any?) -> Unit) {
        callbacks.remove(callback)
    }

    private fun invoke(
        method: String,
        arguments: Any?,
    ) {
        callbacks.forEach { it(method, arguments) }
    }

    fun shutDown() {
        // Do not shutdown the api if other engines are still using it
        if (callbacks.isNotEmpty()) return
        try {
            api.shutDown()
        } catch (e: Exception) {
            // This will throw if the API is already shut down
        }
    }

    override fun blePowerStateChanged(powered: Boolean) {
        invoke("blePowerStateChanged", powered)
    }

    override fun bleSdkFeatureReady(
        identifier: String,
        feature: PolarBleSdkFeature,
    ) {
        invoke("sdkFeatureReady", listOf(identifier, feature.name))
    }

    override fun deviceConnected(polarDeviceInfo: PolarDeviceInfo) {
        invoke("deviceConnected", gson.toJson(polarDeviceInfo))
    }

    override fun deviceConnecting(polarDeviceInfo: PolarDeviceInfo) {
        invoke("deviceConnecting", gson.toJson(polarDeviceInfo))
    }

    override fun deviceDisconnected(polarDeviceInfo: PolarDeviceInfo) {
        invoke(
            "deviceDisconnected",
            // The second argument is the `pairingError` field on iOS
            // Since Android doesn't implement that, always send false
            listOf(gson.toJson(polarDeviceInfo), false),
        )
    }

    override fun disInformationReceived(
        identifier: String,
        uuid: UUID,
        value: String,
    ) {
        invoke("disInformationReceived", listOf(identifier, uuid.toString(), value))
    }

    override fun disInformationReceived(
        identifier: String,
        disInfo: DisInfo,
    ) {
        invoke("disInformationReceived", listOf(identifier, disInfo.key, disInfo.value))
    }

    override fun batteryLevelReceived(
        identifier: String,
        level: Int,
    ) {
        invoke("batteryLevelReceived", listOf(identifier, level))
    }

    @Deprecated("", replaceWith = ReplaceWith(""))
    override fun hrFeatureReady(identifier: String) {
        // Do nothing
    }

    @Deprecated("", replaceWith = ReplaceWith(""))
    override fun hrNotificationReceived(
        identifier: String,
        data: PolarHrData.PolarHrSample,
    ) {
        // Do nothing
    }

    @Deprecated("", replaceWith = ReplaceWith(""))
    override fun polarFtpFeatureReady(identifier: String) {
        // Do nothing
    }

    @Deprecated("", replaceWith = ReplaceWith(""))
    override fun sdkModeFeatureAvailable(identifier: String) {
        // Do nothing
    }

    @Deprecated("", replaceWith = ReplaceWith(""))
    override fun streamingFeaturesReady(
        identifier: String,
        features: Set<PolarDeviceDataType>,
    ) {
        // Do nothing
    }
}

class StreamingChannel(
    messenger: BinaryMessenger,
    name: String,
    private val api: PolarBleApi,
    private val identifier: String,
    private val feature: PolarDeviceDataType,
    private val channel: EventChannel = EventChannel(messenger, name),
) : EventChannel.StreamHandler {
    private var subscription: Disposable? = null

    init {
        channel.setStreamHandler(this)
    }

    override fun onListen(
        arguments: Any?,
        events: EventSink,
    ) {
        // Will be null for some features
        val settings = gson.fromJson(arguments as String, PolarSensorSetting::class.java)

        val stream =
            when (feature) {
                PolarDeviceDataType.HR -> api.startHrStreaming(identifier)
                PolarDeviceDataType.ECG -> api.startEcgStreaming(identifier, settings)
                PolarDeviceDataType.ACC -> api.startAccStreaming(identifier, settings)
                PolarDeviceDataType.PPG -> api.startPpgStreaming(identifier, settings)
                PolarDeviceDataType.PPI -> api.startPpiStreaming(identifier)
                PolarDeviceDataType.GYRO -> api.startGyroStreaming(identifier, settings)
                PolarDeviceDataType.MAGNETOMETER ->
                    api.startMagnetometerStreaming(
                        identifier,
                        settings,
                    )

                PolarDeviceDataType.TEMPERATURE ->
                    api.startTemperatureStreaming(
                        identifier,
                        settings,
                    )
            }

        subscription =
            stream.subscribe({
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
