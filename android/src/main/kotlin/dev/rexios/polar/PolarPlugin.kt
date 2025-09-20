package dev.rexios.polar

import android.annotation.TargetApi
import android.content.Context
import android.os.Build
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
import com.polar.androidcommunications.api.ble.model.gatt.client.ChargeState
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
import com.polar.sdk.api.model.PolarHealthThermometerData
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
import java.time.Instant
import java.time.ZoneId

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
    EventChannel.StreamHandler,
    ActivityAware {
    // Binary messenger for dynamic EventChannel registration
    private lateinit var messenger: BinaryMessenger

    // Method channel
    private lateinit var methodChannel: MethodChannel

    // Event channel
    private lateinit var eventChannel: EventChannel

    // Search channel
    private lateinit var searchChannel: EventChannel

    // Context
    private lateinit var context: Context

    // Streaming channels
    private val streamingChannels = mutableMapOf<String, StreamingChannel>()

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        messenger = flutterPluginBinding.binaryMessenger

        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "polar/methods")
        methodChannel.setMethodCallHandler(this)

        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "polar/events")
        eventChannel.setStreamHandler(this)

        searchChannel = EventChannel(flutterPluginBinding.binaryMessenger, "polar/search")
        searchChannel.setStreamHandler(searchHandler)

        context = flutterPluginBinding.applicationContext
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        searchChannel.setStreamHandler(null)
        streamingChannels.values.forEach { it.dispose() }
        shutDown()
    }

    private fun initApi() {
        if (wrapperInternal == null) {
            wrapperInternal = PolarWrapper(context)
        }
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
            "getAvailableOfflineRecordingDataTypes" -> getAvailableOfflineRecordingDataTypes(
                call,
                result
            )
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
            "isFtuDone" -> isFtuDone(call, result)
            "deleteStoredDeviceData" -> deleteStoredDeviceData(call, result)
            "deleteDeviceDateFolders" -> deleteDeviceDateFolders(call, result)
            "getSteps" -> getSteps(call, result)
            "getDistance" -> getDistance(call, result)
            "getActiveTime" -> getActiveTime(call, result)
            else -> result.notImplemented()
        }
    }

    override fun onListen(
        arguments: Any?,
        events: EventSink,
    ) {
        initApi()
        wrapper.addSink(arguments as Int, events)
    }

    override fun onCancel(arguments: Any?) {
        wrapper.removeSink(arguments as Int)
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

    private fun isFtuDone(call: MethodCall, result: Result) {
        val identifier = call.arguments as? String ?: run {
            result.error("ERROR_INVALID_ARGUMENT", "Expected a single String argument", null)
            return
        }

        wrapper.api
            .isFtuDone(identifier)
            .subscribe({ isFtuDone ->
                runOnUiThread { result.success(isFtuDone) }
            }, {
                runOnUiThread {
                    result.error(it.toString(), it.message, null)
                }
            })
            .discard()
    }

    @TargetApi(Build.VERSION_CODES.O)
    private fun deleteStoredDeviceData(call: MethodCall, result: Result) {
        val arguments = call.arguments as List<*>
        val identifier = arguments[0] as String
        val dataType = gson.fromJson(arguments[1] as String, PolarBleApi.PolarStoredDataType::class.java)
        val until = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).parse(arguments[2] as String)
            .toInstant()
            .atZone(ZoneId.systemDefault())
            .toLocalDate()

        wrapper.api
            .deleteStoredDeviceData(identifier, dataType, until)
            .subscribe({
                runOnUiThread { result.success(null) }
            }, {
                runOnUiThread {
                    result.error(it.toString(), it.message, null)
                }
            })
            .discard()
    }

    @TargetApi(Build.VERSION_CODES.O)
    private fun deleteDeviceDateFolders(call: MethodCall, result: Result) {
        val arguments = call.arguments as List<*>
        val identifier = arguments[0] as String
        val fromDate = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).parse(arguments[1] as String)
            .toInstant()
            .atZone(ZoneId.systemDefault())
            .toLocalDate()
        val toDate = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).parse(arguments[2] as String)
            .toInstant()
            .atZone(ZoneId.systemDefault())
            .toLocalDate()

        wrapper.api
            .deleteDeviceDateFolders(identifier, fromDate, toDate)
            .subscribe({
                runOnUiThread { result.success(null) }
            }, {
                runOnUiThread {
                    result.error(it.toString(), it.message, null)
                }
            })
            .discard()
    }

    private fun getSteps(call: MethodCall, result: Result) {
        try {
            android.util.Log.d("PolarPlugin", "getSteps called with arguments: ${call.arguments}")
            
            val arguments = call.arguments as? List<*>
            if (arguments == null) {
                android.util.Log.e("PolarPlugin", "Arguments are null or not a List")
                result.error("INVALID_ARGUMENTS", "Arguments must be a non-null List", null)
                return
            }
            
            if (arguments.size < 3) {
                android.util.Log.e("PolarPlugin", "Arguments list size is less than 3: ${arguments.size}")
                result.error("INVALID_ARGUMENTS", "Expected 3 arguments: identifier, fromDate, toDate", null)
                return
            }
            
            val identifier = arguments[0] as? String
            if (identifier == null) {
                android.util.Log.e("PolarPlugin", "Identifier is null or not a String")
                result.error("INVALID_ARGUMENTS", "Device identifier must be a non-null String", null)
                return
            }
            
            val fromDateString = arguments[1] as? String
            if (fromDateString == null) {
                android.util.Log.e("PolarPlugin", "fromDate is null or not a String")
                result.error("INVALID_ARGUMENTS", "fromDate must be a non-null String", null)
                return
            }
            
            val toDateString = arguments[2] as? String
            if (toDateString == null) {
                android.util.Log.e("PolarPlugin", "toDate is null or not a String")
                result.error("INVALID_ARGUMENTS", "toDate must be a non-null String", null)
                return
            }
            
            android.util.Log.d("PolarPlugin", "Parsing dates: fromDate=$fromDateString, toDate=$toDateString")
            
            val dateFormat = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
            val fromDate = dateFormat.parse(fromDateString)
            val toDate = dateFormat.parse(toDateString)
            
            if (fromDate == null || toDate == null) {
                android.util.Log.e("PolarPlugin", "Failed to parse dates: fromDate=$fromDate, toDate=$toDate")
                result.error("INVALID_DATE_FORMAT", "Could not parse date strings", null)
                return
            }
            
            android.util.Log.d("PolarPlugin", "Calling Polar API getSteps with identifier=$identifier, fromDate=$fromDate, toDate=$toDate")
            
            // Handle common errors from the Polar API
            wrapper.api
                .getSteps(identifier, fromDate, toDate)
                .onErrorReturn { error ->
                    // Log the error for debugging
                    android.util.Log.e("PolarPlugin", "Error in getSteps API call: ${error.message}", error)
                    
                    // Special handling for specific error types
                    if (error.toString().contains("PftpResponseError") && error.toString().contains("Error: 103")) {
                        android.util.Log.e("PolarPlugin", "PSFTP Protocol error 103 - likely no steps data available for the requested period")
                        // Return an empty list instead of throwing an error
                        emptyList()
                    } else {
                        // For other errors, throw them to be caught by the error handler
                        throw error
                    }
                }
                .subscribe({ stepsDataList: List<com.polar.sdk.api.model.activity.PolarStepsData> ->
                    android.util.Log.d("PolarPlugin", "Received steps data: ${stepsDataList.size} entries")
                    val response = stepsDataList.map { stepsData ->
                        mapOf(
                            "date" to SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(stepsData.date),
                            "steps" to stepsData.steps
                        )
                    }
                    runOnUiThread { 
                        android.util.Log.d("PolarPlugin", "Returning steps data as JSON")
                        result.success(gson.toJson(response)) 
                    }
                }, { error ->
                    android.util.Log.e("PolarPlugin", "Error in getSteps subscription: ${error.message}", error)
                    runOnUiThread { 
                        result.error("GET_STEPS_ERROR", "Error fetching steps data: ${error.message}", null) 
                    }
                })
                .discard()
        } catch (e: Exception) {
            android.util.Log.e("PolarPlugin", "Exception in getSteps", e)
            result.error("UNEXPECTED_ERROR", "Unexpected error in getSteps: ${e.message}", null)
        }
    }

    private fun getDistance(call: MethodCall, result: Result) {
        try {
            android.util.Log.d("PolarPlugin", "getDistance called with arguments: ${call.arguments}")
            
            val arguments = call.arguments as? List<*>
            if (arguments == null) {
                android.util.Log.e("PolarPlugin", "Arguments are null or not a List")
                result.error("INVALID_ARGUMENTS", "Arguments must be a non-null List", null)
                return
            }
            
            if (arguments.size < 3) {
                android.util.Log.e("PolarPlugin", "Arguments list size is less than 3: ${arguments.size}")
                result.error("INVALID_ARGUMENTS", "Expected 3 arguments: identifier, fromDate, toDate", null)
                return
            }
            
            val identifier = arguments[0] as? String
            if (identifier == null) {
                android.util.Log.e("PolarPlugin", "Identifier is null or not a String")
                result.error("INVALID_ARGUMENTS", "Device identifier must be a non-null String", null)
                return
            }
            
            val fromDateString = arguments[1] as? String
            if (fromDateString == null) {
                android.util.Log.e("PolarPlugin", "fromDate is null or not a String")
                result.error("INVALID_ARGUMENTS", "fromDate must be a non-null String", null)
                return
            }
            
            val toDateString = arguments[2] as? String
            if (toDateString == null) {
                android.util.Log.e("PolarPlugin", "toDate is null or not a String")
                result.error("INVALID_ARGUMENTS", "toDate must be a non-null String", null)
                return
            }
            
            android.util.Log.d("PolarPlugin", "Parsing dates: fromDate=$fromDateString, toDate=$toDateString")
            
            val dateFormat = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
            val fromDate = dateFormat.parse(fromDateString)
            val toDate = dateFormat.parse(toDateString)
            
            if (fromDate == null || toDate == null) {
                android.util.Log.e("PolarPlugin", "Failed to parse dates: fromDate=$fromDate, toDate=$toDate")
                result.error("INVALID_DATE_FORMAT", "Could not parse date strings", null)
                return
            }
            
            android.util.Log.d("PolarPlugin", "Calling Polar API getDistance with identifier=$identifier, fromDate=$fromDate, toDate=$toDate")
            
            wrapper.api
                .getDistance(identifier, fromDate, toDate)
                .onErrorReturn { error ->
                    // Log the error for debugging
                    android.util.Log.e("PolarPlugin", "Error in getDistance API call: ${error.message}", error)
                    
                    // Special handling for specific error types
                    if (error.toString().contains("PftpResponseError") && error.toString().contains("Error: 103")) {
                        android.util.Log.e("PolarPlugin", "PSFTP Protocol error 103 - likely no distance data available for the requested period")
                        // Return an empty list instead of throwing an error
                        emptyList()
                    } else {
                        // For other errors, throw them to be caught by the error handler
                        throw error
                    }
                }
                .subscribe({ distanceDataList: List<com.polar.sdk.api.model.activity.PolarDistanceData> ->
                    android.util.Log.d("PolarPlugin", "Received distance data: ${distanceDataList.size} entries")
                    val response = distanceDataList.map { distanceData ->
                        mapOf(
                            "date" to SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(distanceData.date),
                            "distanceMeters" to distanceData.distanceMeters
                        )
                    }
                    runOnUiThread { 
                        android.util.Log.d("PolarPlugin", "Returning distance data as JSON")
                        result.success(gson.toJson(response)) 
                    }
                }, { error ->
                    android.util.Log.e("PolarPlugin", "Error in getDistance subscription: ${error.message}", error)
                    runOnUiThread { 
                        result.error("GET_DISTANCE_ERROR", "Error fetching distance data: ${error.message}", null) 
                    }
                })
                .discard()
        } catch (e: Exception) {
            android.util.Log.e("PolarPlugin", "Exception in getDistance", e)
            result.error("UNEXPECTED_ERROR", "Unexpected error in getDistance: ${e.message}", null)
        }
    }

    private fun getActiveTime(call: MethodCall, result: Result) {
        try {
            android.util.Log.d("PolarPlugin", "getActiveTime called with arguments: ${call.arguments}")
            
            val arguments = call.arguments as? List<*>
            if (arguments == null) {
                android.util.Log.e("PolarPlugin", "Arguments are null or not a List")
                result.error("INVALID_ARGUMENTS", "Arguments must be a non-null List", null)
                return
            }
            
            if (arguments.size < 3) {
                android.util.Log.e("PolarPlugin", "Arguments list size is less than 3: ${arguments.size}")
                result.error("INVALID_ARGUMENTS", "Expected 3 arguments: identifier, fromDate, toDate", null)
                return
            }
            
            val identifier = arguments[0] as? String
            if (identifier == null) {
                android.util.Log.e("PolarPlugin", "Identifier is null or not a String")
                result.error("INVALID_ARGUMENTS", "Device identifier must be a non-null String", null)
                return
            }
            
            val fromDateString = arguments[1] as? String
            if (fromDateString == null) {
                android.util.Log.e("PolarPlugin", "fromDate is null or not a String")
                result.error("INVALID_ARGUMENTS", "fromDate must be a non-null String", null)
                return
            }
            
            val toDateString = arguments[2] as? String
            if (toDateString == null) {
                android.util.Log.e("PolarPlugin", "toDate is null or not a String")
                result.error("INVALID_ARGUMENTS", "toDate must be a non-null String", null)
                return
            }
            
            android.util.Log.d("PolarPlugin", "Parsing dates: fromDate=$fromDateString, toDate=$toDateString")
            
            val dateFormat = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
            val fromDate = dateFormat.parse(fromDateString)
            val toDate = dateFormat.parse(toDateString)
            
            if (fromDate == null || toDate == null) {
                android.util.Log.e("PolarPlugin", "Failed to parse dates: fromDate=$fromDate, toDate=$toDate")
                result.error("INVALID_DATE_FORMAT", "Could not parse date strings", null)
                return
            }
            
            android.util.Log.d("PolarPlugin", "Calling Polar API getActiveTime with identifier=$identifier, fromDate=$fromDate, toDate=$toDate")
            
            wrapper.api
                .getActiveTime(identifier, fromDate, toDate)
                .onErrorReturn { error ->
                    // Log the error for debugging
                    android.util.Log.e("PolarPlugin", "Error in getActiveTime API call: ${error.message}", error)
                    
                    // Special handling for specific error types
                    if (error.toString().contains("PftpResponseError") && error.toString().contains("Error: 103")) {
                        android.util.Log.e("PolarPlugin", "PSFTP Protocol error 103 - likely no active time data available for the requested period")
                        // Return an empty list instead of throwing an error
                        emptyList()
                    } else {
                        // For other errors, throw them to be caught by the error handler
                        throw error
                    }
                }
                .subscribe({ activeTimeDataList: List<com.polar.sdk.api.model.activity.PolarActiveTimeData> ->
                    android.util.Log.d("PolarPlugin", "Received active time data: ${activeTimeDataList.size} entries")
                    val response = activeTimeDataList.map { activeTimeData ->
                        mapOf(
                            "date" to SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(activeTimeData.date),
                            "timeNonWear" to mapActiveTime(activeTimeData.timeNonWear),
                            "timeSleep" to mapActiveTime(activeTimeData.timeSleep),
                            "timeSedentary" to mapActiveTime(activeTimeData.timeSedentary),
                            "timeLightActivity" to mapActiveTime(activeTimeData.timeLightActivity),
                            "timeContinuousModerateActivity" to mapActiveTime(activeTimeData.timeContinuousModerateActivity),
                            "timeIntermittentModerateActivity" to mapActiveTime(activeTimeData.timeIntermittentModerateActivity),
                            "timeContinuousVigorousActivity" to mapActiveTime(activeTimeData.timeContinuousVigorousActivity),
                            "timeIntermittentVigorousActivity" to mapActiveTime(activeTimeData.timeIntermittentVigorousActivity)
                        )
                    }
                    runOnUiThread { 
                        android.util.Log.d("PolarPlugin", "Returning active time data as JSON")
                        result.success(gson.toJson(response)) 
                    }
                }, { error ->
                    android.util.Log.e("PolarPlugin", "Error in getActiveTime subscription: ${error.message}", error)
                    runOnUiThread { 
                        result.error("GET_ACTIVE_TIME_ERROR", "Error fetching active time data: ${error.message}", null) 
                    }
                })
                .discard()
        } catch (e: Exception) {
            android.util.Log.e("PolarPlugin", "Exception in getActiveTime", e)
            result.error("UNEXPECTED_ERROR", "Unexpected error in getActiveTime: ${e.message}", null)
        }
    }

    // Helper function to map PolarActiveTime
    private fun mapActiveTime(time: com.polar.sdk.api.model.activity.PolarActiveTime?): Map<String, Int?>? {
        if (time == null) return null
        
        return mapOf(
            "hours" to time.hours,
            "minutes" to time.minutes,
            "seconds" to time.seconds,
            "millis" to time.millis
        )
    }
    }

class PolarWrapper(
    context: Context,
    val api: PolarBleApi =
        PolarBleApiDefaultImpl.defaultImplementation(
            context,
            PolarBleSdkFeature.values().toSet(),
        ),
    private val sinks: MutableMap<Int, EventSink> = mutableMapOf(),
) : PolarBleApiCallbackProvider {
    init {
        api.setApiCallback(this)
    }

    fun addSink(
        id: Int,
        sink: EventSink,
    ) {
        sinks[id] = sink
    }

    fun removeSink(id: Int) {
        sinks.remove(id)
    }

    private fun success(
        event: String,
        data: Any?,
    ) {
        runOnUiThread { sinks.values.forEach { it.success(mapOf("event" to event, "data" to data)) } }
    }

    fun shutDown() {
        // Do not shutdown the api if other engines are still using it
        if (sinks.isNotEmpty()) return
        try {
            api.shutDown()
        } catch (e: Exception) {
            // This will throw if the API is already shut down
        }
    }

    override fun blePowerStateChanged(powered: Boolean) {
        success("blePowerStateChanged", powered)
    }

    override fun bleSdkFeatureReady(
        identifier: String,
        feature: PolarBleSdkFeature,
    ) {
        success("sdkFeatureReady", listOf(identifier, feature.name))
    }

    override fun deviceConnected(polarDeviceInfo: PolarDeviceInfo) {
        success("deviceConnected", gson.toJson(polarDeviceInfo))
    }

    override fun deviceConnecting(polarDeviceInfo: PolarDeviceInfo) {
        success("deviceConnecting", gson.toJson(polarDeviceInfo))
    }

    override fun deviceDisconnected(polarDeviceInfo: PolarDeviceInfo) {
        success(
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
        success("disInformationReceived", listOf(identifier, uuid.toString(), value))
    }

    override fun disInformationReceived(
        identifier: String,
        disInfo: DisInfo,
    ) {
        success("disInformationReceived", listOf(identifier, disInfo.key, disInfo.value))
    }

    override fun batteryLevelReceived(
        identifier: String,
        level: Int,
    ) {
        success("batteryLevelReceived", listOf(identifier, level))
    }

    override fun batteryChargingStatusReceived(
        identifier: String,
        chargingStatus: ChargeState,
    ) {
        success("batteryChargingStatusReceived", listOf(identifier, chargingStatus.name))
    }

    override fun htsNotificationReceived(
        identifier: String,
        data: PolarHealthThermometerData,
    ) {
        // Do nothing
    }


    @Deprecated("", replaceWith = ReplaceWith(""))
    override fun hrNotificationReceived(
        identifier: String,
        data: PolarHrData.PolarHrSample,
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
                PolarDeviceDataType.PRESSURE -> api.startPressureStreaming(identifier, settings)
                PolarDeviceDataType.SKIN_TEMPERATURE -> api.startSkinTemperatureStreaming(identifier, settings)
                PolarDeviceDataType.LOCATION -> api.startLocationStreaming(identifier, settings)
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