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
    static var api: PolarBleApi!
    let channel: FlutterMethodChannel
    static let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    
    init(channel: FlutterMethodChannel) {
        self.channel = channel
    }
    
    private func initialize() {
        guard Self.api == nil else { return }
        Self.api = PolarBleApiDefaultImpl.polarImplementation(DispatchQueue.main, features: Features.allFeatures.rawValue)
        
        Self.api.observer = self
        Self.api.deviceHrObserver = self
        Self.api.powerStateObserver = self
        Self.api.deviceFeaturesObserver = self
        Self.api.deviceInfoObserver = self
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "polar", binaryMessenger: registrar.messenger())
        let searchChannel = FlutterEventChannel(name: "polar/search", binaryMessenger: registrar.messenger())
        let instance = SwiftPolarPlugin(channel: channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
        
        searchChannel.setStreamHandler(SearchHandler())
    }
    
    class SearchHandler: NSObject, FlutterStreamHandler {
        var sub: Disposable?
        
        func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
            sub = api.searchForDevice().subscribe(onNext: { data in
                guard let data = try? encoder.encode(PolarDeviceInfoCodable(data)),
                      let arguments = String(data: data, encoding: .utf8)
                else { return }
                events(arguments)
            }, onError: { error in
                events((FlutterError(code: "Error in searchForDevice", message: error.localizedDescription, details: nil)))
            }, onCompleted: {
                events(FlutterEndOfEventStream)
            }, onDisposed: {
                events(FlutterEndOfEventStream)
            })
            return nil
        }
        
        func onCancel(withArguments arguments: Any?) -> FlutterError? {
            sub?.dispose()
            return nil
        }
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        initialize()
        
        do {
            switch call.method {
            case "connectToDevice":
                try Self.api.connectToDevice(call.arguments as! String)
                result(nil)
            case "disconnectFromDevice":
                try Self.api.disconnectFromDevice(call.arguments as! String)
                result(nil)
            case "requestStreamSettings":
                let arguments = call.arguments as! [Any]
                try requestStreamSettings(
                    arguments[0] as! String,
                    DeviceStreamingFeature(rawValue: arguments[1] as! Int)!,
                    result
                )
            case "startEcgStreaming":
                let arguments = call.arguments as! [Any]
                try startEcgStreaming(
                    arguments[0] as! String,
                    decoder.decode(PolarSensorSettingCodable.self, from: (arguments[1] as! String)
                        .data(using: .utf8)!).polarSensorSetting
                )
                result(nil)
            case "startAccStreaming":
                let arguments = call.arguments as! [Any]
                try startAccStreaming(
                    arguments[0] as! String,
                    decoder.decode(PolarSensorSettingCodable.self, from: (arguments[1] as! String)
                        .data(using: .utf8)!).polarSensorSetting
                )
                result(nil)
            case "startGyroStreaming":
                let arguments = call.arguments as! [Any]
                try startGyroStreaming(
                    arguments[0] as! String,
                    decoder.decode(PolarSensorSettingCodable.self, from: (arguments[1] as! String)
                        .data(using: .utf8)!).polarSensorSetting
                )
                result(nil)
            case "startMagnetometerStreaming":
                let arguments = call.arguments as! [Any]
                try startMagnetometerStreaming(
                    arguments[0] as! String,
                    decoder.decode(PolarSensorSettingCodable.self, from: (arguments[1] as! String)
                        .data(using: .utf8)!).polarSensorSetting
                )
                result(nil)
            case "startOhrStreaming":
                let arguments = call.arguments as! [Any]
                try startOhrStreaming(
                    arguments[0] as! String,
                    decoder.decode(PolarSensorSettingCodable.self, from: (arguments[1] as! String)
                        .data(using: .utf8)!).polarSensorSetting
                )
                result(nil)
            case "startOhrPPIStreaming":
                try startOhrPPIStreaming(call.arguments as! String)
                result(nil)
            default: result(FlutterMethodNotImplemented)
            }
        } catch {
            result(FlutterError(code: "Error in Polar plugin", message: error.localizedDescription, details: nil))
        }
    }
    
    func requestStreamSettings(_ identifier: String, _ feature: DeviceStreamingFeature, _ result: @escaping FlutterResult) throws {
        _ = Self.api.requestStreamSettings(identifier, feature: feature).subscribe(onSuccess: { data in
            guard let data = try? Self.encoder.encode(PolarSensorSettingCodable(data)),
                  let arguments = String(data: data, encoding: .utf8)
            else { return }
            result(arguments)
        }, onFailure: { result(FlutterError(code: "Unable to request stream settings", message: $0.localizedDescription, details: nil)) })
    }
    
    func startEcgStreaming(_ identifier: String, _ settings: PolarSensorSetting) throws {
        _ = Self.api.startEcgStreaming(identifier, settings: settings).subscribe(onNext: { data in
            guard let data = try? Self.encoder.encode(PolarEcgDataCodable(data)),
                  let arguments = String(data: data, encoding: .utf8)
            else { return }
            self.channel.invokeMethod("ecgDataReceived", arguments: [identifier, arguments])
        }, onError: { NSLog($0.localizedDescription) })
    }
    
    func startAccStreaming(_ identifier: String, _ settings: PolarSensorSetting) throws {
        _ = Self.api.startAccStreaming(identifier, settings: settings).subscribe(onNext: { data in
            guard let data = try? Self.encoder.encode(PolarAccDataCodable(data)),
                  let arguments = String(data: data, encoding: .utf8)
            else { return }
            self.channel.invokeMethod("accDataReceived", arguments: [identifier, arguments])
        }, onError: { NSLog($0.localizedDescription) })
    }
    
    func startGyroStreaming(_ identifier: String, _ settings: PolarSensorSetting) throws {
        _ = Self.api.startGyroStreaming(identifier, settings: settings).subscribe(onNext: { data in
            guard let data = try? Self.encoder.encode(PolarGyroDataCodable(data)),
                  let arguments = String(data: data, encoding: .utf8)
            else { return }
            self.channel.invokeMethod("gyroDataReceived", arguments: [identifier, arguments])
        }, onError: { NSLog($0.localizedDescription) })
    }
    
    func startMagnetometerStreaming(_ identifier: String, _ settings: PolarSensorSetting) throws {
        _ = Self.api.startMagnetometerStreaming(identifier, settings: settings).subscribe(onNext: { data in
            guard let data = try? Self.encoder.encode(PolarMagnetometerDataCodable(data)),
                  let arguments = String(data: data, encoding: .utf8)
            else { return }
            self.channel.invokeMethod("magnetometerDataReceived", arguments: [identifier, arguments])
        }, onError: { NSLog($0.localizedDescription) })
    }
    
    func startOhrStreaming(_ identifier: String, _ settings: PolarSensorSetting) throws {
        _ = Self.api.startOhrStreaming(identifier, settings: settings).subscribe(onNext: { data in
            guard let data = try? Self.encoder.encode(PolarOhrDataCodable(data)),
                  let arguments = String(data: data, encoding: .utf8)
            else { return }
            self.channel.invokeMethod("ohrDataReceived", arguments: [identifier, arguments])
        }, onError: { NSLog($0.localizedDescription) })
    }
    
    func startOhrPPIStreaming(_ identifier: String) throws {
        _ = Self.api.startOhrPPIStreaming(identifier).subscribe(onNext: { data in
            guard let data = try? Self.encoder.encode(PolarPpiDataCodable(data)),
                  let arguments = String(data: data, encoding: .utf8)
            else { return }
            self.channel.invokeMethod("ohrPPIReceived", arguments: [identifier, arguments])
        }, onError: { NSLog($0.localizedDescription) })
    }
    
    public func deviceConnecting(_ polarDeviceInfo: PolarDeviceInfo) {
        guard let data = try? Self.encoder.encode(PolarDeviceInfoCodable(polarDeviceInfo)),
              let arguments = String(data: data, encoding: .utf8)
        else {
            return
        }
        channel.invokeMethod("deviceConnecting", arguments: arguments)
    }
    
    public func deviceConnected(_ polarDeviceInfo: PolarDeviceInfo) {
        guard let data = try? Self.encoder.encode(PolarDeviceInfoCodable(polarDeviceInfo)),
              let arguments = String(data: data, encoding: .utf8)
        else {
            return
        }
        channel.invokeMethod("deviceConnected", arguments: arguments)
    }
    
    public func deviceDisconnected(_ polarDeviceInfo: PolarDeviceInfo) {
        guard let data = try? Self.encoder.encode(PolarDeviceInfoCodable(polarDeviceInfo)),
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
        guard let data = try? Self.encoder.encode(PolarHrDataCodable(data)),
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
        guard let data = try? Self.encoder.encode(streamingFeatures.map { $0.rawValue }),
              let encodedFeatures = String(data: data, encoding: .utf8)
        else {
            return
        }
        channel.invokeMethod("streamingFeaturesReady", arguments: [
            identifier,
            encodedFeatures
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
