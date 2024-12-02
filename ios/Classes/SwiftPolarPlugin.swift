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
    api = PolarBleApiDefaultImpl.polarImplementation(
      DispatchQueue.main, features: Set(PolarBleSdkFeature.allCases))

    api.observer = self
    api.powerStateObserver = self
    api.deviceFeaturesObserver = self
    api.deviceInfoObserver = self
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "polar", binaryMessenger: registrar.messenger())
    let searchChannel = FlutterEventChannel(
      name: "polar/search", binaryMessenger: registrar.messenger())

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
      case "setLedConfig":
        setLedConfig(call, result)
      case "doFactoryReset":
        doFactoryReset(call, result)
      case "enableSdkMode":
        enableSdkMode(call, result)
      case "disableSdkMode":
        disableSdkMode(call, result)
      case "isSdkModeEnabled":
        isSdkModeEnabled(call, result)
      case "getAvailableOfflineRecordingDataTypes":
          getAvailableOfflineRecordingDataTypes(call, result)
      case "requestOfflineRecordingSettings":
          requestOfflineRecordingSettings(call, result)
      case "startOfflineRecording":
          startOfflineRecording(call, result)
      case "stopOfflineRecording":
          stopOfflineRecording(call, result)
      case "getOfflineRecordingStatus":
          getOfflineRecordingStatus(call, result)
      case "listOfflineRecordings":
          listOfflineRecordings(call, result)
      case "getOfflineRecord":
          getOfflineRecord(call, result)
      case "removeOfflineRecord":
          removeOfflineRecord(call, result)
      case "getDiskSpace":
          getDiskSpace(call, result)

      default: result(FlutterMethodNotImplemented)
      }
    } catch {
      result(
        FlutterError(
          code: "Error in Polar plugin", message: error.localizedDescription, details: nil))
    }
  }

  var searchSubscription: Disposable?
  lazy var searchHandler = StreamHandler(
    onListen: { _, events in
      self.initApi()

      self.searchSubscription = self.api.searchForDevice().subscribe(
        onNext: { data in
          guard let data = jsonEncode(PolarDeviceInfoCodable(data))
          else { return }
          DispatchQueue.main.async {
            events(data)
          }
        },
        onError: { error in
          DispatchQueue.main.async {
            events(
              FlutterError(
                code: "Error in searchForDevice", message: error.localizedDescription, details: nil)
            )
          }
        },
        onCompleted: {
          DispatchQueue.main.async {
            events(FlutterEndOfEventStream)
          }
        })
      return nil
    },
    onCancel: { _ in
      self.searchSubscription?.dispose()
      return nil
    })

  private func createStreamingChannel(_ call: FlutterMethodCall, _ result: @escaping FlutterResult)
  {
    let arguments = call.arguments as! [Any]
    let name = arguments[0] as! String
    let identifier = arguments[1] as! String
    let feature = PolarDeviceDataType.allCases[arguments[2] as! Int]

    if streamingChannels[name] == nil {
      streamingChannels[name] = StreamingChannel(messenger, name, api, identifier, feature)
    }

    result(nil)
  }

  func getAvailableOnlineStreamDataTypes(
    _ call: FlutterMethodCall, _ result: @escaping FlutterResult
  ) {
    let identifier = call.arguments as! String

    _ = api.getAvailableOnlineStreamDataTypes(identifier).subscribe(
      onSuccess: { data in
        guard let data = jsonEncode(data.map { PolarDeviceDataType.allCases.firstIndex(of: $0)! })
        else {
          result(
            result(
              FlutterError(
                code: "Unable to get available online stream data types", message: nil, details: nil
              )))
          return
        }
        result(data)
      },
      onFailure: {
        result(
          FlutterError(
            code: "Unable to get available online stream data types",
            message: $0.localizedDescription, details: nil))
      })
  }

  func requestStreamSettings(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
    let arguments = call.arguments as! [Any]
    let identifier = arguments[0] as! String
    let feature = PolarDeviceDataType.allCases[arguments[1] as! Int]

    _ = api.requestStreamSettings(identifier, feature: feature).subscribe(
      onSuccess: { data in
        guard let data = jsonEncode(PolarSensorSettingCodable(data))
        else { return }
        result(data)
      },
      onFailure: {
        result(
          FlutterError(
            code: "Unable to request stream settings", message: $0.localizedDescription,
            details: nil))
      })
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
    ).subscribe(
      onCompleted: {
        result(nil)
      },
      onError: { error in
        result(
          FlutterError(
            code: "Error starting recording", message: error.localizedDescription, details: nil))
      })
  }

  func stopRecording(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let identifier = call.arguments as! String

    _ = api.stopRecording(identifier).subscribe(
      onCompleted: {
        result(nil)
      },
      onError: { error in
        result(
          FlutterError(
            code: "Error stopping recording", message: error.localizedDescription, details: nil))
      })
  }

  func requestRecordingStatus(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let identifier = call.arguments as! String

    _ = api.requestRecordingStatus(identifier).subscribe(
      onSuccess: { data in
        result([data.ongoing, data.entryId])
      },
      onFailure: { error in
        result(
          FlutterError(
            code: "Error stopping recording", message: error.localizedDescription, details: nil))
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
      },
      onError: { error in
        result(
          FlutterError(
            code: "Error listing exercises", message: error.localizedDescription, details: nil))
      },
      onCompleted: {
        result(exercises)
      }
    )
  }

  func fetchExercise(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let arguments = call.arguments as! [Any]
    let identifier = arguments[0] as! String
    let entry = try! decoder.decode(
      PolarExerciseEntryCodable.self,
      from: (arguments[1] as! String)
        .data(using: .utf8)!
    ).data

    _ = api.fetchExercise(identifier, entry: entry).subscribe(
      onSuccess: { data in
        guard let data = jsonEncode(PolarExerciseDataCodable(data))
        else {
          return
        }
        result(data)
      },
      onFailure: { error in
        result(
          FlutterError(
            code: "Error  fetching exercise", message: error.localizedDescription, details: nil))
      })
  }

  func removeExercise(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let arguments = call.arguments as! [Any]
    let identifier = arguments[0] as! String
    let entry = try! decoder.decode(
      PolarExerciseEntryCodable.self,
      from: (arguments[1] as! String)
        .data(using: .utf8)!
    ).data

    _ = api.removeExercise(identifier, entry: entry).subscribe(
      onCompleted: {
        result(nil)
      },
      onError: { error in
        result(
          FlutterError(
            code: "Error removing exercise", message: error.localizedDescription, details: nil))
      })
  }

  func setLedConfig(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let arguments = call.arguments as! [Any]
    let identifier = arguments[0] as! String
    let config = try! decoder.decode(
      LedConfigCodable.self,
      from: (arguments[1] as! String)
        .data(using: .utf8)!
    ).data
    _ = api.setLedConfig(identifier, ledConfig: config).subscribe(
      onCompleted: {
        result(nil)
      },
      onError: { error in
        result(
          FlutterError(
            code: "Error setting led config", message: error.localizedDescription, details: nil))
      })
  }

  func doFactoryReset(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let arguments = call.arguments as! [Any]
    let identifier = arguments[0] as! String
    let preservePairingInformation = arguments[1] as! Bool
    _ = api.doFactoryReset(identifier, preservePairingInformation: preservePairingInformation)
      .subscribe(
        onCompleted: {
          result(nil)
        },
        onError: { error in
          result(
            FlutterError(
              code: "Error doing factory reset", message: error.localizedDescription, details: nil))
        })
  }

  func enableSdkMode(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let identifier = call.arguments as! String
    _ = api.enableSDKMode(identifier).subscribe(
      onCompleted: {
        result(nil)
      },
      onError: { error in
        result(
          FlutterError(
            code: "Error enabling SDK mode", message: error.localizedDescription, details: nil))
      })
  }

  func disableSdkMode(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let identifier = call.arguments as! String
    _ = api.disableSDKMode(identifier).subscribe(
      onCompleted: {
        result(nil)
      },
      onError: { error in
        result(
          FlutterError(
            code: "Error disabling SDK mode", message: error.localizedDescription, details: nil))
      })
  }

  func isSdkModeEnabled(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let identifier = call.arguments as! String
    _ = api.isSDKModeEnabled(identifier).subscribe(
      onSuccess: {
        result($0)
      },
      onFailure: { error in
        result(
          FlutterError(
            code: "Error checking SDK mode status", message: error.localizedDescription,
            details: nil))
      })
  }

  private func invokeMethod(_ methodName: String, arguments: Any? = nil) {
    DispatchQueue.main.async {
      self.channel.invokeMethod(methodName, arguments: arguments)
    }
  }

  public func deviceConnecting(_ polarDeviceInfo: PolarDeviceInfo) {
    guard let data = jsonEncode(PolarDeviceInfoCodable(polarDeviceInfo))
    else {
      return
    }
    invokeMethod("deviceConnecting", arguments: data)
  }

  public func deviceConnected(_ polarDeviceInfo: PolarDeviceInfo) {
    guard let data = jsonEncode(PolarDeviceInfoCodable(polarDeviceInfo))
    else {
      return
    }
    invokeMethod("deviceConnected", arguments: data)
  }

  public func deviceDisconnected(_ polarDeviceInfo: PolarDeviceInfo, pairingError: Bool) {
    guard let data = jsonEncode(PolarDeviceInfoCodable(polarDeviceInfo))
    else {
      return
    }
    invokeMethod("deviceDisconnected", arguments: [data, pairingError])
  }

  public func batteryLevelReceived(_ identifier: String, batteryLevel: UInt) {
    invokeMethod("batteryLevelReceived", arguments: [identifier, batteryLevel])
  }

  public func blePowerOn() {
    invokeMethod("blePowerStateChanged", arguments: true)
  }

  public func blePowerOff() {
    invokeMethod("blePowerStateChanged", arguments: false)
  }

  public func bleSdkFeatureReady(_ identifier: String, feature: PolarBleSdkFeature) {
    invokeMethod(
      "sdkFeatureReady",
      arguments: [
        identifier,
        PolarBleSdkFeature.allCases.firstIndex(of: feature)!,
      ])
  }

  public func disInformationReceived(_ identifier: String, uuid: CBUUID, value: String) {
    invokeMethod(
      "disInformationReceived", arguments: [identifier, uuid.uuidString, value])
  }

  public func disInformationReceivedWithKeysAsStrings(
    _ identifier: String, key: String, value: String
  ) {
    channel.invokeMethod("disInformationReceived", arguments: [identifier, key, value])
  }

  // MARK: Deprecated functions

  public func streamingFeaturesReady(
    _ identifier: String, streamingFeatures: Set<PolarBleSdk.PolarDeviceDataType>
  ) {
    // Do nothing
  }

  public func hrFeatureReady(_ identifier: String) {
    // Do nothing
  }

  public func ftpFeatureReady(_ identifier: String) {
    // Do nothing
  }

  func getAvailableOfflineRecordingDataTypes(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
      guard let identifier = call.arguments as? String else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "Identifier is not a string", details: nil))
          return
      }

      // Use the api to get available offline recording data types
      _ = api.getAvailableOfflineRecordingDataTypes(identifier).subscribe(
          onSuccess: { dataTypes in
              // Map data types to their respective indices
              let dataTypesIds = dataTypes.compactMap { PolarDeviceDataType.allCases.firstIndex(of: $0) }
              // Safely convert indices to description strings and return
              let dataTypesDescriptions = dataTypesIds.map { "\($0)" }
              result(dataTypesDescriptions)
          },
          onFailure: { error in
              result(FlutterError(
                  code: "ERROR_GETTING_DATA_TYPES", 
                  message: error.localizedDescription, 
                  details: nil
              ))
          }
      )
  }

func requestOfflineRecordingSettings(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [Any] else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "Arguments are not in expected format", details: nil))
        return
    }
    guard let identifier = arguments[0] as? String else {
        result(FlutterError(code: "INVALID_IDENTIFIER", message: "Identifier is not a string", details: nil))
        return
    }
    guard let index = arguments[1] as? Int, index < PolarDeviceDataType.allCases.count else {
        result(FlutterError(code: "INVALID_FEATURE", message: "Feature index is out of bounds", details: nil))
        return
    }
    let feature = PolarDeviceDataType.allCases[index]

    _ = api.requestStreamSettings(identifier, feature: feature)
        .subscribe(onSuccess: { settings in
            if let encodedData = jsonEncode(PolarSensorSettingCodable(settings)) {
                result(encodedData)
            } else {
                result(FlutterError(code: "ENCODING_ERROR", message: "Failed to encode stream settings", details: nil))
            }
        }, onFailure: { error in
            result(FlutterError(code: "REQUEST_ERROR", message: "Error requesting stream settings: \(error.localizedDescription)", details: nil))
        })
}

  func startOfflineRecording(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
      let arguments = call.arguments as! [Any]
      let identifier = arguments[0] as! String
      let feature = PolarDeviceDataType.allCases[arguments[1] as! Int]
      // Attempt to decode the sensor settings
      let settingsData = arguments[2] as? String
      let settings = settingsData != nil ? try? decoder.decode(
          PolarSensorSettingCodable.self, 
          from: settingsData!.data(using: .utf8)!
      ).data : nil

      _ = api.startOfflineRecording(identifier, feature: feature, settings: settings, secret: nil)
          .subscribe(onCompleted: {
              result(nil)
          }, onError: { error in
              result(FlutterError(code: "Error starting offline recording", message: error.localizedDescription, details: nil))
          })
  }

  func stopOfflineRecording(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {

      let arguments = call.arguments as! [Any]
      let identifier = arguments[0] as! String
      let feature = PolarDeviceDataType.allCases[arguments[1] as! Int]

      api.stopOfflineRecording(identifier,feature:feature).subscribe(onCompleted: {

      result(nil)

      }, onError: { error in

          result(FlutterError(code: "Error stopping offline recording", message: error.localizedDescription.description, details: nil))
      })
  }

  func getOfflineRecordingStatus(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
      let identifier = call.arguments as! String

      _ = api.getOfflineRecordingStatus(identifier)
          .subscribe(onSuccess: { statusDict in
              let status = statusDict.map { key, value in
                  [PolarDeviceDataType.allCases.firstIndex(of: key)!: value]
              }
              result(status)
          }, onFailure: { error in
              result(
                FlutterError(code: "Error getting offline recording status", message: error.localizedDescription, details: nil)
              )
          })
  }

  func listOfflineRecordings(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
      guard let identifier = call.arguments as? String else {
          result(FlutterError(code: "INVALID_ARGUMENTS", message: "Expected a string identifier as argument", details: nil))
          return
      }

      api.listOfflineRecordings(identifier).debug("listOfflineRecordings")
          .toArray()
          .subscribe(
              onSuccess: { entries in
                  var jsonStringList: [String] = []

                  do {
                      let encoder = JSONEncoder()
                      encoder.dateEncodingStrategy = .millisecondsSince1970
                      for entry in entries {
                          // Use PolarOfflineRecordingEntryCodable for encoding
                          let entryCodable = PolarOfflineRecordingEntryCodable(entry)
                          let data = try encoder.encode(entryCodable)
                          if let jsonString = String(data: data, encoding: .utf8) {
                              jsonStringList.append(jsonString)
                          }
                      }
                      result(jsonStringList) // Return the array of JSON strings
                  } catch {
                      result(FlutterError(code: "ENCODE_ERROR", message: "Failed to encode entries to JSON", details: nil))
                  }
              },
              onFailure: { error in
                  result(FlutterError(code: "ERROR", message: "Offline recording listing error: \(error.localizedDescription)", details: nil))
              }
          )
  }

  func getOfflineRecord(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let arguments = call.arguments as! [Any]
    let identifier = arguments[0] as! String
    let entryJsonString = arguments[1] as! String

    guard let entryData = entryJsonString.data(using: .utf8) else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid entry JSON string", details: nil))
        return
    }

    do {
        let entry = try JSONDecoder().decode(PolarOfflineRecordingEntryCodable.self, from: entryData).data

        _ = api.getOfflineRecord(identifier, entry: entry, secret: nil)
            .subscribe(
                onSuccess: { recordingData in
                    do {
                        // Use the PolarOfflineRecordingDataCodable to encode the data to JSON
                        let dataCodable = PolarOfflineRecordingDataCodable(recordingData)
                        let encoder = JSONEncoder()
                        encoder.dateEncodingStrategy = .millisecondsSince1970
                        let data = try encoder.encode(dataCodable)
                        if let jsonString = String(data: data, encoding: .utf8) {
                            result(jsonString)
                        } else {
                            result(FlutterError(code: "ENCODE_ERROR", message: "Failed to encode recording data to JSON string", details: nil))
                        }
                    } catch {
                        result(FlutterError(code: "ENCODE_ERROR", message: "Failed to encode recording data to JSON", details: nil))
                    }
                },
                onFailure: { error in
                    result(FlutterError(code: "FETCH_ERROR", message: "Failed to fetch recording: \(error.localizedDescription)", details: nil))
                }
            )
    } catch {
        result(FlutterError(code: "DECODE_ERROR", message: "Failed to decode entry JSON", details: nil))
    }
  }

  func removeOfflineRecord(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
      let arguments = call.arguments as! [Any]
      let identifier = arguments[0] as! String
      let entryJsonString = arguments[1] as! String

      guard let entryData = entryJsonString.data(using: .utf8) else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid entry JSON string", details: nil))
          return
      }

      do {
          let entry = try! JSONDecoder().decode(PolarOfflineRecordingEntryCodable.self, from: entryData).data

          _ = api.removeOfflineRecord(identifier, entry: entry).subscribe(onCompleted: {
              result(nil)
          }, onError: { error in
              result(FlutterError(code: "Error removing exercise", message: error.localizedDescription, details: nil))
          })
      }
  }

  func getDiskSpace(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
      let identifier = call.arguments as! String
      _ = api.getDiskSpace(identifier).subscribe(onSuccess: { diskSpaceData in
          do {
              let diskSpaceDataCodable = PolarDiskSpaceDataCodable(diskSpaceData)
              let encoder = JSONEncoder()
              let data = try encoder.encode(diskSpaceDataCodable)
              if let jsonString = String(data: data, encoding: .utf8) {
                  result(jsonString)
              } else {
                  result(FlutterError(code: "ENCODE_ERROR", message: "Failed to encode disk space data to JSON string", details: nil))
              }
          } catch {
              result(FlutterError(code: "ENCODE_ERROR", message: "Failed to encode disk space data: \(error.localizedDescription)", details: nil))
          }
      }, onFailure: { error in
          result(FlutterError(code: "Error getting disk space", message: error.localizedDescription, details: nil))
      })
  }
}

class StreamHandler: NSObject, FlutterStreamHandler {
  let onListen: (Any?, @escaping FlutterEventSink) -> FlutterError?
  let onCancel: (Any?) -> FlutterError?

  init(
    onListen: @escaping (Any?, @escaping FlutterEventSink) -> FlutterError?,
    onCancel: @escaping (Any?) -> FlutterError?
  ) {
    self.onListen = onListen
    self.onCancel = onCancel
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
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

  init(
    _ messenger: FlutterBinaryMessenger, _ name: String, _ api: PolarBleApi, _ identifier: String,
    _ feature: PolarDeviceDataType
  ) {
    self.api = api
    self.identifier = identifier
    self.feature = feature
    self.channel = FlutterEventChannel(name: name, binaryMessenger: messenger)

    super.init()

    channel.setStreamHandler(self)
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    // Will be null for some features
    let settings = try? decoder.decode(
      PolarSensorSettingCodable.self,
      from: (arguments as! String)
        .data(using: .utf8)!
    ).data

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
    case .temperature:
      stream = api.startTemperatureStreaming(identifier, settings: settings!)
    case .pressure:
      stream = api.startPressureStreaming(identifier, settings: settings!)
    }

    subscription = stream.anySubscribe(
      onNext: { data in
        guard let data = jsonEncode(PolarDataCodable(data)) else {
          return
        }
        DispatchQueue.main.async {
          events(data)
        }
      },
      onError: { error in
        DispatchQueue.main.async {
          events(
            FlutterError(
              code: "Error while streaming", message: error.localizedDescription, details: nil))
        }
      },
      onCompleted: {
        DispatchQueue.main.async {
          events(FlutterEndOfEventStream)
        }
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
