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
    var deviceId: String?
    
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
                instance.api.connectToDevice(call.arguments as! String)
            case "disconnectFromDevice":
                instance.api.disconnectFromDevice(call.arguments as! String)
            default: break
            }
        }
    }
    
    public func deviceConnecting(_ polarDeviceInfo: PolarDeviceInfo) {}
    
    public func deviceConnected(_ polarDeviceInfo: PolarDeviceInfo) {
        channel.invokeMethod("deviceConnected", arguments: )
    }
    
    public func deviceDisconnected(_ polarDeviceInfo: PolarDeviceInfo) {
        channel.invokeMethod("connection", arguments: false)
    }
    
    public func batteryLevelReceived(_ identifier: String, batteryLevel: UInt) {
        channel.invokeMethod("battery", arguments: batteryLevel)
    }
    
    public func hrValueReceived(_ identifier: String, data: PolarHrData) {
        channel.invokeMethod("hr", arguments: data.hr)
        channel.invokeMethod("rrs", arguments: data.rrs)
    }
    
    public func hrFeatureReady(_ identifier: String) {}
    
    public func streamingFeaturesReady(_ identifier: String, streamingFeatures: Set<DeviceStreamingFeature>) {}
    
    public func blePowerOn() {}
    
    public func blePowerOff() {}
        
    public func ftpFeatureReady(_ identifier: String) {}
}
