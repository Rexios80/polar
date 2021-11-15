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
    PolarBleApiDeviceHrObserver
{
    var api = PolarBleApiDefaultImpl.polarImplementation(DispatchQueue.main, features: Features.allFeatures.rawValue)
    let channel: FlutterMethodChannel
    let encoder = JSONEncoder()
    
    init(channel: FlutterMethodChannel) {
        self.channel = channel
        
        super.init()
        
        api.observer = self
        api.deviceHrObserver = self
        api.powerStateObserver = self
        api.deviceFeaturesObserver = self
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = SwiftPolarPlugin(channel: FlutterMethodChannel(name: "polar", binaryMessenger: registrar.messenger()))
        registrar.addMethodCallDelegate(instance, channel: instance.channel)

        let decoder = JSONDecoder()
        
        instance.channel.setMethodCallHandler {
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            do {
                switch call.method {
                case "connectToDevice":
                    try instance.api.connectToDevice(call.arguments as! String)
                case "disconnectFromDevice":
                    try instance.api.disconnectFromDevice(call.arguments as! String)
                case "requestStreamSettings":
                    let arguments = call.arguments as! [Any]
                    try instance.requestStreamSettings(
                        arguments[0] as! String,
                        DeviceStreamingFeature(rawValue: arguments[1] as! Int)!,
                        result
                    )
                case "startEcgStreaming":
                    let arguments = call.arguments as! [Any]
                    try instance.startEcgStreaming(
                        arguments[0] as! String,
                        decoder.decode(PolarSensorSettingCodable.self, from: (arguments[1] as! String)
                            .data(using: .utf8)!)
                            .polarSensorSetting
                    )
                case "startAccStreaming":
                    let arguments = call.arguments as! [Any]
                    try instance.startAccStreaming(
                        arguments[0] as! String,
                        decoder.decode(PolarSensorSettingCodable.self, from: (arguments[1] as! String)
                            .data(using: .utf8)!)
                            .polarSensorSetting
                    )
                case "startGyroStreaming":
                    let arguments = call.arguments as! [Any]
                    try instance.startGyroStreaming(
                        arguments[0] as! String,
                        decoder.decode(PolarSensorSettingCodable.self, from: (arguments[1] as! String)
                            .data(using: .utf8)!)
                            .polarSensorSetting
                    )
                case "startMagnetometerStreaming":
                    let arguments = call.arguments as! [Any]
                    try instance.startMagnetometerStreaming(
                        arguments[0] as! String,
                        decoder.decode(PolarSensorSettingCodable.self, from: (arguments[1] as! String)
                            .data(using: .utf8)!)
                            .polarSensorSetting
                    )
                case "startOhrStreaming":
                    let arguments = call.arguments as! [Any]
                    try instance.startOhrStreaming(
                        arguments[0] as! String,
                        decoder.decode(PolarSensorSettingCodable.self, from: (arguments[1] as! String)
                            .data(using: .utf8)!)
                            .polarSensorSetting
                    )
                case "startOhrPPIStreaming":
                    try instance.startOhrPPIStreaming(call.arguments as! String)
                default: result(FlutterMethodNotImplemented)
                }
            } catch {
                NSLog(error.localizedDescription)
                result(error)
            }
        }
    }
    
    func requestStreamSettings(_ identifier: String, _ feature: DeviceStreamingFeature, _ result: @escaping FlutterResult) throws {
        _ = api.requestStreamSettings(identifier, feature: feature).subscribe(onSuccess: { data in
            guard let data = try? self.encoder.encode(PolarSensorSettingCodable(data)),
                  let arguments = String(data: data, encoding: .utf8)
            else { return }
            result(arguments)
        }, onFailure: { result($0.localizedDescription) })
    }
    
    func startEcgStreaming(_ identifier: String, _ settings: PolarSensorSetting) throws {
        _ = api.startEcgStreaming(identifier, settings: settings).subscribe(onNext: { data in
            guard let data = try? self.encoder.encode(PolarEcgDataCodable(data)),
                  let arguments = String(data: data, encoding: .utf8)
            else { return }
            self.channel.invokeMethod("ecgDataReceived", arguments: [identifier, arguments])
        }, onError: { NSLog($0.localizedDescription) })
    }
    
    func startAccStreaming(_ identifier: String, _ settings: PolarSensorSetting) throws {
        _ = api.startAccStreaming(identifier, settings: settings).subscribe(onNext: { data in
            guard let data = try? self.encoder.encode(PolarAccDataCodable(data)),
                  let arguments = String(data: data, encoding: .utf8)
            else { return }
            self.channel.invokeMethod("accDataReceived", arguments: [identifier, arguments])
        }, onError: { NSLog($0.localizedDescription) })
    }
    
    func startGyroStreaming(_ identifier: String, _ settings: PolarSensorSetting) throws {
        _ = api.startGyroStreaming(identifier, settings: settings).subscribe(onNext: { data in
            guard let data = try? self.encoder.encode(PolarGyroDataCodable(data)),
                  let arguments = String(data: data, encoding: .utf8)
            else { return }
            self.channel.invokeMethod("gyroDataReceived", arguments: [identifier, arguments])
        }, onError: { NSLog($0.localizedDescription) })
    }
    
    func startMagnetometerStreaming(_ identifier: String, _ settings: PolarSensorSetting) throws {
        _ = api.startMagnetometerStreaming(identifier, settings: settings).subscribe(onNext: { data in
            guard let data = try? self.encoder.encode(PolarMagnetometerDataCodable(data)),
                  let arguments = String(data: data, encoding: .utf8)
            else { return }
            self.channel.invokeMethod("magnetometerDataReceived", arguments: [identifier, arguments])
        }, onError: { NSLog($0.localizedDescription) })
    }
    
    func startOhrStreaming(_ identifier: String, _ settings: PolarSensorSetting) throws {
        _ = api.startOhrStreaming(identifier, settings: settings).subscribe(onNext: { data in
            guard let data = try? self.encoder.encode(PolarOhrDataCodable(data)),
                  let arguments = String(data: data, encoding: .utf8)
            else { return }
            self.channel.invokeMethod("ohrDataReceived", arguments: [identifier, arguments])
        }, onError: { NSLog($0.localizedDescription) })
    }
    
    func startOhrPPIStreaming(_ identifier: String) throws {
        _ = api.startOhrPPIStreaming(identifier).subscribe(onNext: { data in
            guard let data = try? self.encoder.encode(PolarPpiDataCodable(data)),
                  let arguments = String(data: data, encoding: .utf8)
            else { return }
            self.channel.invokeMethod("ohrPPIReceived", arguments: [identifier, arguments])
        }, onError: { NSLog($0.localizedDescription) })
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
        guard let data = try? encoder.encode(streamingFeatures.map { $0.rawValue }),
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
}
