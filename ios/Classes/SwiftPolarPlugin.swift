import CoreBluetooth
import Flutter
import PolarBleSdk
import RxSwift
import UIKit

private let encoder = JSONEncoder()
private let decoder = JSONDecoder()

private func jsonEncode(_ value: Encodable) -> String? {
    guard let data = try? encoder.encode(value),
          let data = String(data: data, encoding: .utf8)
    else {
        return nil
    }

    return data
}

public class SwiftPolarPlugin:
    NSObject,
    FlutterPlugin,
    PolarBleApiObserver,
    PolarBleApiPowerStateObserver,
    PolarBleApiDeviceFeaturesObserver,
    PolarBleApiDeviceInfoObserver
{
    /// Binary messenger for dynamic EventChannel registration
    let messenger: FlutterBinaryMessenger

    /// Method channel
    let channel: FlutterMethodChannel

    /// Search channel
    let searchChannel: FlutterEventChannel

    /// Streaming channels
    var streamingChannels = [String: StreamingChannel]()

    var api: PolarBleApi!

    init(
        messenger: FlutterBinaryMessenger,
        channel: FlutterMethodChannel,
        searchChannel: FlutterEventChannel
    ) {
        self.messenger = messenger
        self.channel = channel
        self.searchChannel = searchChannel
    }

    private func initApi() {
        guard api == nil else { return }
        api = PolarBleApiDefaultImpl.polarImplementation(DispatchQueue.main, features: Set(PolarBleSdkFeature.allCases))

        api.observer = self
        api.powerStateObserver = self
        api.deviceFeaturesObserver = self
        api.deviceInfoObserver = self
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "polar", binaryMessenger: registrar.messenger())
        let searchChannel = FlutterEventChannel(name: "polar/search", binaryMessenger: registrar.messenger())

        let instance = SwiftPolarPlugin(
            messenger: registrar.messenger(),
            channel: channel,
            searchChannel: searchChannel
        )

        registrar.addMethodCallDelegate(instance, channel: channel)
        searchChannel.setStreamHandler(instance.searchHandler)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        initApi()

        do {
            switch call.method {
            case "connectToDevice":
                try api.connectToDevice(call.arguments as! String)
                result(nil)
            case "disconnectFromDevice":
                try api.disconnectFromDevice(call.arguments as! String)
                result(nil)
            case "getAvailableOnlineStreamDataTypes":
                getAvailableOnlineStreamDataTypes(call, result)
            case "requestStreamSettings":
                try requestStreamSettings(call, result)
            case "createStreamingChannel":
                createStreamingChannel(call, result)
            case "startRecording":
                startRecording(call, result)
            case "stopRecording":
                stopRecording(call, result)
            case "requestRecordingStatus":
                requestRecordingStatus(call, result)
            case "listExercises":
                listExercises(call, result)
            case "fetchExercise":
                fetchExercise(call, result)
            case "removeExercise":
                removeExercise(call, result)
            default: result(FlutterMethodNotImplemented)
            }
        } catch {
            result(FlutterError(code: "Error in Polar plugin", message: error.localizedDescription, details: nil))
        }
    }

    var searchSubscription: Disposable?
    lazy var searchHandler = StreamHandler(onListen: { _, events in
        self.initApi()

        self.searchSubscription = self.api.searchForDevice().subscribe(onNext: { data in
            guard let data = jsonEncode(PolarDeviceInfoCodable(data))
            else { return }
            events(data)
        }, onError: { error in
            events(FlutterError(code: "Error in searchForDevice", message: error.localizedDescription, details: nil))
        }, onCompleted: {
            events(FlutterEndOfEventStream)
        })
        return nil
    }, onCancel: { _ in
        self.searchSubscription?.dispose()
        return nil
    })

    private func createStreamingChannel(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let arguments = call.arguments as! [Any]
        let name = arguments[0] as! String
        let identifier = arguments[1] as! String
        let feature = PolarDeviceDataType.allCases[arguments[2] as! Int]

        if streamingChannels[name] == nil {
            streamingChannels[name] = StreamingChannel(messenger, name, api, identifier, feature)
        }

        result(nil)
    }

    func getAvailableOnlineStreamDataTypes(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let identifier = call.arguments as! String

        _ = api.getAvailableOnlineStreamDataTypes(identifier).subscribe(onSuccess: { data in
            guard let data = jsonEncode(data.map { PolarDeviceDataType.allCases.firstIndex(of: $0)! })
            else {
                result(result(FlutterError(code: "Unable to get available online stream data types", message: nil, details: nil)))
                return
            }
            result(data)
        }, onFailure: { result(FlutterError(code: "Unable to get available online stream data types", message: $0.localizedDescription, details: nil)) })
    }

    func requestStreamSettings(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        let arguments = call.arguments as! [Any]
        let identifier = arguments[0] as! String
        let feature = PolarDeviceDataType.allCases[arguments[1] as! Int]

        _ = api.requestStreamSettings(identifier, feature: feature).subscribe(onSuccess: { data in
            guard let data = jsonEncode(PolarSensorSettingCodable(data))
            else { return }
            result(data)
        }, onFailure: { result(FlutterError(code: "Unable to request stream settings", message: $0.localizedDescription, details: nil)) })
    }

    func startRecording(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let arguments = call.arguments as! [Any]
        let identifier = arguments[0] as! String
        let exerciseId = arguments[1] as! String
        let interval = RecordingInterval(rawValue: arguments[2] as! Int)!
        let sampleType = SampleType(rawValue: arguments[3] as! Int)!

        _ = api.startRecording(
            identifier,
            exerciseId: exerciseId,
            interval: interval,
            sampleType: sampleType
        ).subscribe(onCompleted: {
            result(nil)
        }, onError: { error in
            result(FlutterError(code: "Error starting recording", message: error.localizedDescription, details: nil))
        })
    }

    func stopRecording(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let identifier = call.arguments as! String

        _ = api.stopRecording(identifier).subscribe(onCompleted: {
            result(nil)
        }, onError: { error in
            result(FlutterError(code: "Error stopping recording", message: error.localizedDescription, details: nil))
        })
    }

    func requestRecordingStatus(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let identifier = call.arguments as! String

        _ = api.requestRecordingStatus(identifier).subscribe(onSuccess: { data in
            result([data.ongoing, data.entryId])
        }, onFailure: { error in
            result(FlutterError(code: "Error stopping recording", message: error.localizedDescription, details: nil))
        })
    }

    func listExercises(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let identifier = call.arguments as! String

        var exercises = [String]()
        _ = api.fetchStoredExerciseList(identifier).subscribe(
            onNext: { data in
                guard let data = jsonEncode(PolarExerciseEntryCodable(data))
                else {
                    return
                }
                exercises.append(data)
            }, onError: { error in
                result(FlutterError(code: "Error listing exercises", message: error.localizedDescription, details: nil))
            }, onCompleted: {
                result(exercises)
            }
        )
    }

    func fetchExercise(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let arguments = call.arguments as! [Any]
        let identifier = arguments[0] as! String
        let entry = try! decoder.decode(PolarExerciseEntryCodable.self, from: (arguments[1] as! String)
            .data(using: .utf8)!).data

        _ = api.fetchExercise(identifier, entry: entry).subscribe(onSuccess: { data in
            guard let data = jsonEncode(PolarExerciseDataCodable(data))
            else {
                return
            }
            result(data)
        }, onFailure: { error in
            result(FlutterError(code: "Error  fetching exercise", message: error.localizedDescription, details: nil))
        })
    }

    func removeExercise(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let arguments = call.arguments as! [Any]
        let identifier = arguments[0] as! String
        let entry = try! decoder.decode(PolarExerciseEntryCodable.self, from: (arguments[1] as! String)
            .data(using: .utf8)!).data

        _ = api.removeExercise(identifier, entry: entry).subscribe(onCompleted: {
            result(nil)
        }, onError: { error in
            result(FlutterError(code: "Error removing exercise", message: error.localizedDescription, details: nil))
        })
    }

    public func deviceConnecting(_ polarDeviceInfo: PolarDeviceInfo) {
        guard let data = jsonEncode(PolarDeviceInfoCodable(polarDeviceInfo))
        else {
            return
        }
        channel.invokeMethod("deviceConnecting", arguments: data)
    }

    public func deviceConnected(_ polarDeviceInfo: PolarDeviceInfo) {
        guard let data = jsonEncode(PolarDeviceInfoCodable(polarDeviceInfo))
        else {
            return
        }
        channel.invokeMethod("deviceConnected", arguments: data)
    }

    public func deviceDisconnected(_ polarDeviceInfo: PolarDeviceInfo) {
        guard let data = jsonEncode(PolarDeviceInfoCodable(polarDeviceInfo))
        else {
            return
        }
        channel.invokeMethod("deviceDisconnected", arguments: data)
    }

    public func batteryLevelReceived(_ identifier: String, batteryLevel: UInt) {
        channel.invokeMethod("batteryLevelReceived", arguments: [identifier, batteryLevel])
    }

    public func blePowerOn() {
        channel.invokeMethod("blePowerStateChanged", arguments: true)
    }

    public func blePowerOff() {
        channel.invokeMethod("blePowerStateChanged", arguments: false)
    }

    public func bleSdkFeatureReady(_ identifier: String, feature: PolarBleSdkFeature) {
        channel.invokeMethod("sdkFeatureReady", arguments: [
            identifier,
            PolarBleSdkFeature.allCases.firstIndex(of: feature)!,
        ])
    }

    public func disInformationReceived(_ identifier: String, uuid: CBUUID, value: String) {
        channel.invokeMethod("disInformationReceived", arguments: [identifier, uuid.uuidString, value])
    }

    // MARK: Deprecated functions

    public func streamingFeaturesReady(_ identifier: String, streamingFeatures: Set<PolarBleSdk.PolarDeviceDataType>) {
        // Do nothing
    }

    public func hrFeatureReady(_ identifier: String) {
        // Do nothing
    }

    public func ftpFeatureReady(_ identifier: String) {
        // Do nothing
    }
}

class StreamHandler: NSObject, FlutterStreamHandler {
    let onListen: (Any?, @escaping FlutterEventSink) -> FlutterError?
    let onCancel: (Any?) -> FlutterError?

    init(onListen: @escaping (Any?, @escaping FlutterEventSink) -> FlutterError?, onCancel: @escaping (Any?) -> FlutterError?) {
        self.onListen = onListen
        self.onCancel = onCancel
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        return onListen(arguments, events)
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        return onCancel(arguments)
    }
}

protocol AnyObservable {
    func anySubscribe(
        onNext: ((Any) -> Void)?,
        onError: ((Swift.Error) -> Void)?,
        onCompleted: (() -> Void)?
    ) -> Disposable
}

extension Observable: AnyObservable {
    public func anySubscribe(
        onNext: ((Any) -> Void)? = nil,
        onError: ((Swift.Error) -> Void)? = nil,
        onCompleted: (() -> Void)? = nil
    ) -> Disposable {
        subscribe(onNext: onNext, onError: onError, onCompleted: onCompleted)
    }
}

class StreamingChannel: NSObject, FlutterStreamHandler {
    let api: PolarBleApi
    let identifier: String
    let feature: PolarDeviceDataType
    let channel: FlutterEventChannel

    var subscription: Disposable?

    init(_ messenger: FlutterBinaryMessenger, _ name: String, _ api: PolarBleApi, _ identifier: String, _ feature: PolarDeviceDataType) {
        self.api = api
        self.identifier = identifier
        self.feature = feature
        self.channel = FlutterEventChannel(name: name, binaryMessenger: messenger)

        super.init()

        channel.setStreamHandler(self)
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        // Will be null for some features
        let settings = try? decoder.decode(PolarSensorSettingCodable.self, from: (arguments as! String)
            .data(using: .utf8)!).data

        let stream: AnyObservable
        switch feature {
        case .ecg:
            stream = api.startEcgStreaming(identifier, settings: settings!)
        case .acc:
            stream = api.startAccStreaming(identifier, settings: settings!)
        case .ppg:
            stream = api.startPpgStreaming(identifier, settings: settings!)
        case .ppi:
            stream = api.startPpiStreaming(identifier)
        case .gyro:
            stream = api.startGyroStreaming(identifier, settings: settings!)
        case .magnetometer:
            stream = api.startMagnetometerStreaming(identifier, settings: settings!)
        case .hr:
            stream = api.startHrStreaming(identifier)
        }

        subscription = stream.anySubscribe(onNext: { data in
            guard let data = jsonEncode(PolarDataCodable(data)) else {
                return
            }
            events(data)
        }, onError: { error in
            events(FlutterError(code: "Error while streaming", message: error.localizedDescription, details: nil))
        }, onCompleted: {
            events(FlutterEndOfEventStream)
        })

        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        subscription?.dispose()
        return nil
    }

    func dispose() {
        subscription?.dispose()
        channel.setStreamHandler(nil)
    }
}
