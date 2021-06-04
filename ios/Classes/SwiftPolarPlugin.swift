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

        instance.channel.setMethodCallHandler {
            (call: FlutterMethodCall, _: @escaping FlutterResult) -> Void in
            switch call.method {
            case "connectToDevice":
                try? instance.api.connectToDevice(call.arguments as! String)
            case "disconnectFromDevice":
                try? instance.api.disconnectFromDevice(call.arguments as! String)
            default: break
            }
        }
    }
    
    public func deviceConnecting(_ polarDeviceInfo: PolarDeviceInfo) {
        channel.invokeMethod("deviceConnecting", arguments: try? encoder.encode(PolarDeviceInfoCodable(polarDeviceInfo)))
    }
    
    public func deviceConnected(_ polarDeviceInfo: PolarDeviceInfo) {
        channel.invokeMethod("deviceConnected", arguments: try? encoder.encode(PolarDeviceInfoCodable(polarDeviceInfo)))
    }
    
    public func deviceDisconnected(_ polarDeviceInfo: PolarDeviceInfo) {
        channel.invokeMethod("deviceDisconnected", arguments: try? encoder.encode(PolarDeviceInfoCodable(polarDeviceInfo)))
    }
    
    public func batteryLevelReceived(_ identifier: String, batteryLevel: UInt) {
        channel.invokeMethod("batteryLevelReceived", arguments: [identifier, batteryLevel])
    }
    
    public func hrValueReceived(_ identifier: String, data: PolarHrData) {
        channel.invokeMethod("hrNotificationReceived", arguments: try? encoder.encode(PolarHrDataCodable(data)))
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
