import CoreBluetooth
import Flutter
import PolarBleSdk
import RxSwift
import UIKit

public class SwiftPolarPlugin:
    NSObject,
    FlutterPlugin,
    PolarBleApiObserver,
    PolarBleApiPowerStateObserver,
    PolarBleApiDeviceFeaturesObserver,
    PolarBleApiDeviceHrObserver,
    PolarBleApiDeviceInfoObserver
{
    var api: PolarBleApi!
    let channel: FlutterMethodChannel
    let searchChannel: FlutterEventChannel
    let streamingChannel: FlutterEventChannel
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    init(
        channel: FlutterMethodChannel,
        searchChannel: FlutterEventChannel,
        streamingChannel: FlutterEventChannel
    ) {
        self.channel = channel
        self.searchChannel = searchChannel
        self.streamingChannel = streamingChannel
    }

    private func initApi() {
        guard api == nil else { return }
        api = PolarBleApiDefaultImpl.polarImplementation(DispatchQueue.main, features: Features.allFeatures.rawValue)

        api.observer = self
        api.deviceHrObserver = self
        api.powerStateObserver = self
        api.deviceFeaturesObserver = self
        api.deviceInfoObserver = self
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "polar", binaryMessenger: registrar.messenger())
        let searchChannel = FlutterEventChannel(name: "polar/search", binaryMessenger: registrar.messenger())
        let streamingChannel = FlutterEventChannel(name: "polar/streaming", binaryMessenger: registrar.messenger())

        let instance = SwiftPolarPlugin(
            channel: channel,
            searchChannel: searchChannel,
            streamingChannel: streamingChannel
        )

        registrar.addMethodCallDelegate(instance, channel: channel)
        searchChannel.setStreamHandler(instance.searchHandler)
        streamingChannel.setStreamHandler(instance.streamingHandler)
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
            case "requestStreamSettings":
                try requestStreamSettings(call, result)
            case "startRecording":
                startRecording(call, result)
            case "stopRecording":
                stopRecording(call, result)
            case "requestRecordingStatus":
                requestRecordingStatus(call, result)
            case "listExercises":
                listExercises(call, result)
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
            guard let data = try? self.encoder.encode(PolarDeviceInfoCodable(data)),
                  let arguments = String(data: data, encoding: .utf8)
            else { return }
            events(arguments)
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

    // Map of <feature, <identifier, subscription>>
    var streamingSubscriptions = [DeviceStreamingFeature: [String: Disposable]]()
    lazy var streamingHandler = StreamHandler(onListen: { arguments, events in
        let arguments = arguments as! [Any?]
        let feature = DeviceStreamingFeature(rawValue: arguments[0] as! Int)!
        let identifier = arguments[1] as! String
        // Will be null for ppi feature
        let settings = try? self.decoder.decode(PolarSensorSettingCodable.self, from: (arguments[2] as! String)
            .data(using: .utf8)!).data

        let stream: AnyObservable
        switch feature {
        case .ecg:
            stream = self.api.startEcgStreaming(identifier, settings: settings!)
        case .acc:
            stream = self.api.startAccStreaming(identifier, settings: settings!)
        case .gyro:
            stream = self.api.startGyroStreaming(identifier, settings: settings!)
        case .magnetometer:
            stream = self.api.startMagnetometerStreaming(identifier, settings: settings!)
        case .ppg:
            stream = self.api.startOhrStreaming(identifier, settings: settings!)
        case .ppi:
            stream = self.api.startOhrPPIStreaming(identifier)
        }

        let sub = stream.anySubscribe(onNext: { data in
            let encodedData: Any?
            switch feature {
            case .ecg:
                encodedData = try? self.encoder.encode(PolarEcgDataCodable(data as! PolarEcgData))
            case .acc:
                encodedData = try? self.encoder.encode(PolarAccDataCodable(data as! PolarAccData))
            case .gyro:
                encodedData = try? self.encoder.encode(PolarGyroDataCodable(data as! PolarGyroData))
            case .magnetometer:
                encodedData = try? self.encoder.encode(PolarMagnetometerDataCodable(data as! PolarMagnetometerData))
            case .ppg:
                encodedData = try? self.encoder.encode(PolarOhrDataCodable(data as! PolarOhrData))
            case .ppi:
                encodedData = try? self.encoder.encode(PolarPpiDataCodable(data as! PolarPpiData))
            }

            guard let data = encodedData as? Data, let arguments = String(data: data, encoding: .utf8) else {
                return
            }
            events(arguments)
        }, onError: { error in
            events(FlutterError(code: "Error while streaming", message: error.localizedDescription, details: nil))
        }, onCompleted: {
            events(FlutterEndOfEventStream)
        })

        if self.streamingSubscriptions[feature] == nil {
            self.streamingSubscriptions[feature] = [:]
        }

        self.streamingSubscriptions[feature]![identifier] = sub

        return nil
    }, onCancel: { arguments in
        let arguments = arguments as! [Any?]
        let feature = DeviceStreamingFeature(rawValue: arguments[0] as! Int)!
        let identifier = arguments[1] as! String

        self.streamingSubscriptions[feature]?[identifier]?.dispose()

        return nil
    })

    func requestStreamSettings(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        let arguments = call.arguments as! [Any]
        let identifier = arguments[0] as! String
        let feature = DeviceStreamingFeature(rawValue: arguments[1] as! Int)!

        _ = api.requestStreamSettings(identifier, feature: feature).subscribe(onSuccess: { data in
            guard let data = try? self.encoder.encode(PolarSensorSettingCodable(data)),
                  let arguments = String(data: data, encoding: .utf8)
            else { return }
            result(arguments)
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
                guard let data = try? self.encoder.encode(PolarExerciseEntryCodable(data)),
                      let arguments = String(data: data, encoding: .utf8) else {
                    return
                }
                exercises.append(arguments)
            }, onError: { error in
                result(FlutterError(code: "Error listing exercises", message: error.localizedDescription, details: nil))
            }, onCompleted: {
                result(exercises)
            }
        )
    }

    public func deviceConnecting(_ polarDeviceInfo: PolarDeviceInfo) {
        guard let data = try? encoder.encode(PolarDeviceInfoCodable(polarDeviceInfo)),
              let arguments = String(data: data, encoding: .utf8)
        else {
            return
        }
        channel.invokeMethod("deviceConnecting", arguments: arguments)
    }

    public func deviceConnected(_ polarDeviceInfo: PolarDeviceInfo) {
        guard let data = try? encoder.encode(PolarDeviceInfoCodable(polarDeviceInfo)),
              let arguments = String(data: data, encoding: .utf8)
        else {
            return
        }
        channel.invokeMethod("deviceConnected", arguments: arguments)
    }

    public func deviceDisconnected(_ polarDeviceInfo: PolarDeviceInfo) {
        guard let data = try? encoder.encode(PolarDeviceInfoCodable(polarDeviceInfo)),
              let arguments = String(data: data, encoding: .utf8)
        else {
            return
        }
        channel.invokeMethod("deviceDisconnected", arguments: arguments)
    }

    public func batteryLevelReceived(_ identifier: String, batteryLevel: UInt) {
        channel.invokeMethod("batteryLevelReceived", arguments: [identifier, batteryLevel])
    }

    public func hrValueReceived(_ identifier: String, data: PolarHrData) {
        guard let data = try? encoder.encode(PolarHrDataCodable(data)),
              let arguments = String(data: data, encoding: .utf8)
        else {
            return
        }
        channel.invokeMethod("hrNotificationReceived", arguments: [identifier, arguments])
    }

    public func hrFeatureReady(_ identifier: String) {
        channel.invokeMethod("hrFeatureReady", arguments: identifier)
    }

    public func streamingFeaturesReady(_ identifier: String, streamingFeatures: Set<DeviceStreamingFeature>) {
        guard let data = try? encoder.encode(streamingFeatures.map(\.rawValue)),
              let encodedFeatures = String(data: data, encoding: .utf8)
        else {
            return
        }
        channel.invokeMethod("streamingFeaturesReady", arguments: [
            identifier,
            encodedFeatures,
        ])
    }

    public func blePowerOn() {
        channel.invokeMethod("blePowerStateChanged", arguments: true)
    }

    public func blePowerOff() {
        channel.invokeMethod("blePowerStateChanged", arguments: false)
    }

    public func ftpFeatureReady(_ identifier: String) {
        channel.invokeMethod("ftpFeatureReady", arguments: identifier)
    }

    public func disInformationReceived(_ identifier: String, uuid: CBUUID, value: String) {
        channel.invokeMethod("disInformationReceived", arguments: [identifier, uuid.uuidString, value])
    }
}

class StreamHandler: NSObject, FlutterStreamHandler {
    final let onListen: (Any?, @escaping FlutterEventSink) -> FlutterError?
    final let onCancel: (Any?) -> FlutterError?

    init(onListen: @escaping (Any?, @escaping FlutterEventSink) -> FlutterError?, onCancel: @escaping (Any?) -> FlutterError?) {
        self.onListen = onListen
        self.onCancel = onCancel
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        onListen(arguments, events)
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        onCancel(arguments)
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
