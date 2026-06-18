package dev.rexios.polar

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
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
import com.polar.androidcommunications.api.ble.model.gatt.client.PowerSourcesState
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
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import java.lang.reflect.Type
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.LocalTime
import java.time.OffsetDateTime
import java.time.ZoneId
import java.time.ZonedDateTime
import java.util.Date
import java.util.UUID

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

object LocalDateSerializer : JsonDeserializer<LocalDate>, JsonSerializer<LocalDate> {
    override fun deserialize(
        json: JsonElement?,
        typeOfT: Type?,
        context: JsonDeserializationContext?,
    ): LocalDate {
        val dateString = json?.asJsonPrimitive?.asString ?: ""
        return try {
            LocalDate.parse(dateString)
        } catch (e: java.time.format.DateTimeParseException) {
            // Handle epoch milliseconds (e.g. from Flutter's DateTime.millisecondsSinceEpoch)
            java.time.Instant.ofEpochMilli(dateString.toLong())
                .atZone(java.time.ZoneId.systemDefault())
                .toLocalDate()
        }
    }

    override fun serialize(
        src: LocalDate?,
        typeOfSrc: Type?,
        context: JsonSerializationContext?,
    ): JsonElement = JsonPrimitive(src?.toString())
}

object ZonedDateTimeSerializer : JsonDeserializer<ZonedDateTime>, JsonSerializer<ZonedDateTime> {
    override fun deserialize(
        json: JsonElement?,
        typeOfT: Type?,
        context: JsonDeserializationContext?,
    ): ZonedDateTime {
        val dateTimeString = json?.asJsonPrimitive?.asString ?: ""
        return try {
            // ISO_ZONED_DATE_TIME — requires a region in brackets,
            // e.g. "2026-05-12T15:21:19+02:00[Europe/Brussels]".
            ZonedDateTime.parse(dateTimeString)
        } catch (e: java.time.format.DateTimeParseException) {
            try {
                // ISO_OFFSET_DATE_TIME — offset only, no region.
                // e.g. "2026-05-12T15:21:19+02:00" or "...Z". This is the
                // shape the polar plugin's Dart serializer produces, and
                // the shape iOS's ISO8601DateFormatter expects.
                OffsetDateTime.parse(dateTimeString).toZonedDateTime()
            } catch (_: java.time.format.DateTimeParseException) {
                // Local datetime with no zone (e.g. Flutter's plain DateTime.toIso8601String()).
                LocalDateTime.parse(dateTimeString).atZone(ZoneId.systemDefault())
            }
        }
    }

    override fun serialize(
        src: ZonedDateTime?,
        typeOfSrc: Type?,
        context: JsonSerializationContext?,
    ): JsonElement = JsonPrimitive(src?.toString())
}

object LocalTimeSerializer : JsonDeserializer<LocalTime>, JsonSerializer<LocalTime> {
    override fun deserialize(
        json: JsonElement?,
        typeOfT: Type?,
        context: JsonDeserializationContext?,
    ): LocalTime {
        val timeString = json?.asJsonPrimitive?.asString ?: ""
        return LocalTime.parse(timeString)
    }

    override fun serialize(
        src: LocalTime?,
        typeOfSrc: Type?,
        context: JsonSerializationContext?,
    ): JsonElement = JsonPrimitive(src?.toString())
}

private fun runOnUiThread(runnable: () -> Unit) {
    Handler(Looper.getMainLooper()).post { runnable() }
}

private val gson =
    GsonBuilder()
        .registerTypeAdapter(Date::class.java, DateSerializer)
        .registerTypeAdapter(LocalDate::class.java, LocalDateSerializer)
        .registerTypeAdapter(LocalTime::class.java, LocalTimeSerializer)
        .registerTypeAdapter(ZonedDateTime::class.java, ZonedDateTimeSerializer)
        .create()

private var wrapperInternal: PolarWrapper? = null
private val wrapper: PolarWrapper
    get() = wrapperInternal!!

private val pluginScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

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

            "getAvailableOnlineStreamDataTypes" -> {
                getAvailableOnlineStreamDataTypes(call, result)
            }

            "getAvailableHrServiceDataTypes" -> {
                getAvailableHrServiceDataTypes(call, result)
            }

            "requestStreamSettings" -> {
                requestStreamSettings(call, result)
            }

            "createStreamingChannel" -> {
                createStreamingChannel(call, result)
            }

            "startRecording" -> {
                startRecording(call, result)
            }

            "stopRecording" -> {
                stopRecording(call, result)
            }

            "requestRecordingStatus" -> {
                requestRecordingStatus(call, result)
            }

            "listExercises" -> {
                listExercises(call, result)
            }

            "fetchExercise" -> {
                fetchExercise(call, result)
            }

            "removeExercise" -> {
                removeExercise(call, result)
            }

            "setLedConfig" -> {
                setLedConfig(call, result)
            }

            "doFactoryReset" -> {
                doFactoryReset(call, result)
            }

            "enableSdkMode" -> {
                enableSdkMode(call, result)
            }

            "disableSdkMode" -> {
                disableSdkMode(call, result)
            }

            "isSdkModeEnabled" -> {
                isSdkModeEnabled(call, result)
            }

            "doFirstTimeUse" -> {
                doFirstTimeUse(call, result)
            }

            "isFtuDone" -> {
                isFtuDone(call, result)
            }

            "get247HrSamples" -> {
                get247HrSamples(call, result)
            }

            else -> {
                result.notImplemented()
            }
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
        val id = arguments as? Int ?: return
        wrapper.removeSink(id)
    }

    private val searchHandler =
        object : EventChannel.StreamHandler {
            private var searchJob: Job? = null

            override fun onListen(
                arguments: Any?,
                events: EventSink,
            ) {
                initApi()

                searchJob =
                    pluginScope.launch {
                        try {
                            wrapper.api.searchForDevice().collect { device ->
                                runOnUiThread { events.success(gson.toJson(device)) }
                            }
                            runOnUiThread { events.endOfStream() }
                        } catch (e: Throwable) {
                            runOnUiThread { events.error(e.toString(), e.message, null) }
                        }
                    }
            }

            override fun onCancel(arguments: Any?) {
                searchJob?.cancel()
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
                    Event.ON_RESUME -> {
                        wrapperInternal?.api?.foregroundEntered()
                    }

                    Event.ON_DESTROY -> {
                        shutDown()
                    }

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
        pluginScope.launch {
            try {
                val types = wrapper.api.getAvailableOnlineStreamDataTypes(identifier)
                runOnUiThread { result.success(gson.toJson(types)) }
            } catch (e: Throwable) {
                runOnUiThread { result.error(e.toString(), e.message, null) }
            }
        }
    }

    private fun getAvailableHrServiceDataTypes(
        call: MethodCall,
        result: Result,
    ) {
        val identifier = call.arguments as String
        pluginScope.launch {
            try {
                val types = wrapper.api.getAvailableHRServiceDataTypes(identifier)
                runOnUiThread { result.success(gson.toJson(types)) }
            } catch (e: Throwable) {
                runOnUiThread { result.error(e.toString(), e.message, null) }
            }
        }
    }

    private fun requestStreamSettings(
        call: MethodCall,
        result: Result,
    ) {
        val arguments = call.arguments as List<*>
        val identifier = arguments[0] as String
        val feature = gson.fromJson(arguments[1] as String, PolarDeviceDataType::class.java)
        pluginScope.launch {
            try {
                val settings = wrapper.api.requestStreamSettings(identifier, feature)
                runOnUiThread { result.success(gson.toJson(settings)) }
            } catch (e: Throwable) {
                runOnUiThread { result.error(e.toString(), e.message, null) }
            }
        }
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
        pluginScope.launch {
            try {
                wrapper.api.startRecording(identifier, exerciseId, interval, sampleType)
                runOnUiThread { result.success(null) }
            } catch (e: Throwable) {
                runOnUiThread { result.error(e.toString(), e.message, null) }
            }
        }
    }

    private fun stopRecording(
        call: MethodCall,
        result: Result,
    ) {
        val identifier = call.arguments as String
        pluginScope.launch {
            try {
                wrapper.api.stopRecording(identifier)
                runOnUiThread { result.success(null) }
            } catch (e: Throwable) {
                runOnUiThread { result.error(e.toString(), e.message, null) }
            }
        }
    }

    private fun requestRecordingStatus(
        call: MethodCall,
        result: Result,
    ) {
        val identifier = call.arguments as String
        pluginScope.launch {
            try {
                val status = wrapper.api.requestRecordingStatus(identifier)
                runOnUiThread { result.success(listOf(status.first, status.second)) }
            } catch (e: Throwable) {
                runOnUiThread { result.error(e.toString(), e.message, null) }
            }
        }
    }

    private fun listExercises(
        call: MethodCall,
        result: Result,
    ) {
        val identifier = call.arguments as String
        val exercises = mutableListOf<String>()
        pluginScope.launch {
            try {
                wrapper.api.listExercises(identifier).collect { entry ->
                    exercises.add(gson.toJson(entry))
                }
                runOnUiThread { result.success(exercises) }
            } catch (e: Throwable) {
                runOnUiThread { result.error(e.toString(), e.message, null) }
            }
        }
    }

    private fun fetchExercise(
        call: MethodCall,
        result: Result,
    ) {
        val arguments = call.arguments as List<*>
        val identifier = arguments[0] as String
        val entry = gson.fromJson(arguments[1] as String, PolarExerciseEntry::class.java)
        pluginScope.launch {
            try {
                val data = wrapper.api.fetchExercise(identifier, entry)
                runOnUiThread { result.success(gson.toJson(data)) }
            } catch (e: Throwable) {
                runOnUiThread { result.error(e.toString(), e.message, null) }
            }
        }
    }

    private fun removeExercise(
        call: MethodCall,
        result: Result,
    ) {
        val arguments = call.arguments as List<*>
        val identifier = arguments[0] as String
        val entry = gson.fromJson(arguments[1] as String, PolarExerciseEntry::class.java)
        pluginScope.launch {
            try {
                wrapper.api.removeExercise(identifier, entry)
                runOnUiThread { result.success(null) }
            } catch (e: Throwable) {
                runOnUiThread { result.error(e.toString(), e.message, null) }
            }
        }
    }

    private fun setLedConfig(
        call: MethodCall,
        result: Result,
    ) {
        val arguments = call.arguments as List<*>
        val identifier = arguments[0] as String
        val config = gson.fromJson(arguments[1] as String, LedConfig::class.java)
        pluginScope.launch {
            try {
                wrapper.api.setLedConfig(identifier, config)
                runOnUiThread { result.success(null) }
            } catch (e: Throwable) {
                runOnUiThread { result.error(e.toString(), e.message, null) }
            }
        }
    }

    private fun doFactoryReset(
        call: MethodCall,
        result: Result,
    ) {
        val arguments = call.arguments as List<*>
        val identifier = arguments[0] as String
        val preservePairingInformation = arguments[1] as Boolean
        pluginScope.launch {
            try {
                wrapper.api.doFactoryReset(identifier, preservePairingInformation)
                runOnUiThread { result.success(null) }
            } catch (e: Throwable) {
                runOnUiThread { result.error(e.toString(), e.message, null) }
            }
        }
    }

    private fun enableSdkMode(
        call: MethodCall,
        result: Result,
    ) {
        val identifier = call.arguments as String
        pluginScope.launch {
            try {
                wrapper.api.enableSDKMode(identifier)
                runOnUiThread { result.success(null) }
            } catch (e: Throwable) {
                runOnUiThread { result.error(e.toString(), e.message, null) }
            }
        }
    }

    private fun disableSdkMode(
        call: MethodCall,
        result: Result,
    ) {
        val identifier = call.arguments as String
        pluginScope.launch {
            try {
                wrapper.api.disableSDKMode(identifier)
                runOnUiThread { result.success(null) }
            } catch (e: Throwable) {
                runOnUiThread { result.error(e.toString(), e.message, null) }
            }
        }
    }

    private fun isSdkModeEnabled(
        call: MethodCall,
        result: Result,
    ) {
        val identifier = call.arguments as String
        pluginScope.launch {
            try {
                val enabled = wrapper.api.isSDKModeEnabled(identifier)
                runOnUiThread { result.success(enabled) }
            } catch (e: Throwable) {
                runOnUiThread { result.error(e.toString(), e.message, null) }
            }
        }
    }

    // The Polar Android SDK parses deviceTime with
    // DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss'Z'") — the 'Z' is a *literal*
    // character, not a zone marker. The Dart plugin emits offset form ("+02:00"), so
    // strip any zone/offset info and append a literal Z.
    private fun normalizeDeviceTime(input: String): String {
        return try {
            "${OffsetDateTime.parse(input).toLocalDateTime().withNano(0)}Z"
        } catch (e: java.time.format.DateTimeParseException) {
            try {
                "${LocalDateTime.parse(input).withNano(0)}Z"
            } catch (e2: java.time.format.DateTimeParseException) {
                input
            }
        }
    }

    private fun doFirstTimeUse(
        call: MethodCall,
        result: Result,
    ) {
        val arguments = call.arguments as List<*>
        val identifier = arguments[0] as String
        val ftuConfig = gson.fromJson(arguments[1] as String, PolarFirstTimeUseConfig::class.java)
        val normalizedConfig =
            ftuConfig.copy(deviceTime = normalizeDeviceTime(ftuConfig.deviceTime))
        pluginScope.launch {
            try {
                wrapper.api.doFirstTimeUse(identifier, normalizedConfig)
                runOnUiThread { result.success(null) }
            } catch (e: Throwable) {
                runOnUiThread { result.error(e.toString(), e.message, null) }
            }
        }
    }

    private fun isFtuDone(
        call: MethodCall,
        result: Result,
    ) {
        val identifier = call.arguments as String
        pluginScope.launch {
            try {
                val done = wrapper.api.isFtuDone(identifier)
                runOnUiThread { result.success(done) }
            } catch (e: Throwable) {
                runOnUiThread { result.error(e.toString(), e.message, null) }
            }
        }
    }

    private fun get247HrSamples(
        call: MethodCall,
        result: Result,
    ) {
        Log.d("PolarPlugin", "get247HrSamples called with args: ${call.arguments}")
        val arguments = call.arguments as List<*>
        val identifier = arguments[0] as String
        val fromDate = LocalDate.parse(arguments[1] as String)
        val toDate = LocalDate.parse(arguments[2] as String)

        Log.d("PolarPlugin", "Fetching 247 HR from $fromDate to $toDate for device: $identifier")
        pluginScope.launch {
            try {
                val hrSamplesList = wrapper.api.get247HrSamples(identifier, fromDate, toDate)
                Log.d("PolarPlugin", "Received ${hrSamplesList.size} day(s) of data")
                Log.v("PolarPlugin", "Raw data: $hrSamplesList")
                runOnUiThread { result.success(gson.toJson(hrSamplesList)) }
            } catch (error: Throwable) {
                Log.e("PolarPlugin", "Error fetching 247 HR data: ${error.message}", error)

                // Provide more helpful error messages for common protobuf issues
                val errorMessage = when {
                    error.message?.contains("InvalidProtocolBufferException") == true ->
                        "Failed to parse 24/7 HR data. This may be caused by:\n" +
                                "1. Corrupted data on the device\n" +
                                "2. No 24/7 HR data recorded for the requested period\n" +
                                "3. Firmware version incompatibility\n" +
                                "Try syncing with Polar Flow app or requesting a different date range."

                    error.message?.contains("Message was missing required fields") == true ->
                        "Incomplete 24/7 HR data on device. The data may be corrupted or not yet recorded. " +
                                "Try syncing with Polar Flow app or ensure the device has been wearing and recording data."

                    else -> error.message ?: "Unknown error"
                }

                runOnUiThread {
                    result.error(error::class.java.simpleName, errorMessage, null)
                }
            }
        }
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
        runOnUiThread {
            sinks.values.forEach {
                it.success(
                    mapOf(
                        "event" to event,
                        "data" to data
                    )
                )
            }
        }
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

    override fun bleSdkFeaturesReadiness(
        identifier: String,
        ready: List<PolarBleSdkFeature>,
        unavailable: List<PolarBleSdkFeature>,
    ) {
        success(
            "sdkFeaturesReadiness",
            listOf(identifier, ready.map { it.name }, unavailable.map { it.name }),
        )
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

    override fun powerSourcesStateReceived(
        identifier: String,
        powerSourcesState: PowerSourcesState,
    ) {
        // No-op — not surfaced through the Dart API. The SDK calls this on
        // connect; throwing here used to crash the app (NotImplementedError).
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
    private var streamingJob: Job? = null

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
                PolarDeviceDataType.MAGNETOMETER -> api.startMagnetometerStreaming(
                    identifier,
                    settings
                )

                PolarDeviceDataType.TEMPERATURE -> api.startTemperatureStreaming(
                    identifier,
                    settings
                )

                PolarDeviceDataType.PRESSURE -> api.startPressureStreaming(identifier, settings)
                PolarDeviceDataType.SKIN_TEMPERATURE -> api.startSkinTemperatureStreaming(
                    identifier,
                    settings
                )

                PolarDeviceDataType.LOCATION -> api.startLocationStreaming(identifier, settings)
            }

        streamingJob =
            pluginScope.launch {
                try {
                    stream.collect { sample ->
                        runOnUiThread { events.success(gson.toJson(sample)) }
                    }
                    runOnUiThread { events.endOfStream() }
                } catch (e: Throwable) {
                    runOnUiThread { events.error(e.toString(), e.message, null) }
                }
            }
    }

    override fun onCancel(arguments: Any?) {
        streamingJob?.cancel()
    }

    fun dispose() {
        streamingJob?.cancel()
        channel.setStreamHandler(null)
    }
}
