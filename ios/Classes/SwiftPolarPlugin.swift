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
    let api = PolarBleApiDefaultImpl.polarImplementation(DispatchQueue.main, features: Features.allFeatures.rawValue)
    let channel: FlutterMethodChannel
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    
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

        instance.channel.setMethodCallHandler {
            (call: FlutterMethodCall, _: @escaping FlutterResult) -> Void in
            do {
                switch call.method {
                case "connectToDevice":
                    try instance.api.connectToDevice(call.arguments as! String)
                case "disconnectFromDevice":
                    try instance.api.disconnectFromDevice(call.arguments as! String)
                case "startEcgStreaming":
                    try instance.api.startEcgStreaming(
                        call.arguments[0] as! String,
                        decoder.decode(PolarEcgData.Type, from: call.arguments[1] as! String)
                    )
                case "startAccStreaming":
                    try instance.api.startAccStreaming(
                        call.arguments[0] as! String,
                        decoder.decode(PolarAccData.Type, from: call.arguments[1] as! String)
                    )
                case "startGyroStreaming":
                    try instance.api.startGyroStreaming(
                        call.arguments[0] as! String,
                        decoder.decode(PolarGyroData.Type, from: call.arguments[1] as! String)
                    )
                case "startMagnetometerStreaming":
                    try instance.api.startMagnetometerStreaming(
                        call.arguments[0] as! String,
                        decoder.decode(PolarMagnetometerData.Type, from: call.arguments[1] as! String)
                    )
                case "startOhrStreaming":
                    try instance.api.startOhrStreaming(
                        call.arguments[0] as! String,
                        decoder.decode(PolarOhrData.Type, from: call.arguments[1] as! String)
                    )
                case "startOhrPPIStreaming":
                    try instance.api.startOhrPPIStreaming(
                        call.arguments[0] as! String
                        decoder.decode(PolarPpiData.Type, from: call.arguments[1] as! String)
                    )
                default: break
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    public func deviceConnecting(_ polarDeviceInfo: PolarDeviceInfo) {
        guard let data = try? encoder.encode(PolarDeviceInfoCodable(polarDeviceInfo)), let arguments = String(data: data, encoding: .utf8) else {
            return
        }
        channel.invokeMethod("deviceConnecting", arguments: arguments)
    }
    
    public func deviceConnected(_ polarDeviceInfo: PolarDeviceInfo) {
        guard let data = try? encoder.encode(PolarDeviceInfoCodable(polarDeviceInfo)), let arguments = String(data: data, encoding: .utf8) else {
            return
        }
        channel.invokeMethod("deviceConnected", arguments: arguments)
    }
    
    public func deviceDisconnected(_ polarDeviceInfo: PolarDeviceInfo) {
        guard let data = try? encoder.encode(PolarDeviceInfoCodable(polarDeviceInfo)), let arguments = String(data: data, encoding: .utf8) else {
            return
        }
        channel.invokeMethod("deviceDisconnected", arguments: arguments)
    }
    
    public func batteryLevelReceived(_ identifier: String, batteryLevel: UInt) {
        channel.invokeMethod("batteryLevelReceived", arguments: [identifier, batteryLevel])
    }
    
    public func hrValueReceived(_ identifier: String, data: PolarHrData) {
        guard let data = try? encoder.encode(PolarHrDataCodable(data)), let arguments = String(data: data, encoding: .utf8) else {
            return
        }
        channel.invokeMethod("hrNotificationReceived", arguments: [identifier, arguments])
    }
    
    public func hrFeatureReady(_ identifier: String) {
        channel.invokeMethod("hrFeatureReady", arguments: identifier)
    }
    
    public func streamingFeaturesReady(_ identifier: String, streamingFeatures: Set<DeviceStreamingFeature>) {
        channel.invokeMethod("streamingFeaturesReady", arguments: [identifier, streamingFeatures.description])
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
