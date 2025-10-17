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
  FlutterStreamHandler,
  PolarBleApiObserver,
  PolarBleApiPowerStateObserver,
  PolarBleApiDeviceFeaturesObserver,
  PolarBleApiDeviceInfoObserver
{
  /// Binary messenger for dynamic EventChannel registration
  let messenger: FlutterBinaryMessenger

  /// Method channel
  let methodChannel: FlutterMethodChannel

  /// Event channel
  let eventChannel: FlutterEventChannel

  /// Search channel
  let searchChannel: FlutterEventChannel

  /// Streaming channels
  var streamingChannels = [String: StreamingChannel]()

  var api: PolarBleApi!
  var events: FlutterEventSink?
    
  init(
    messenger: FlutterBinaryMessenger,
    methodChannel: FlutterMethodChannel,
    eventChannel: FlutterEventChannel,
    searchChannel: FlutterEventChannel
  ) {
    self.messenger = messenger
    self.methodChannel = methodChannel
    self.eventChannel = eventChannel
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
      let methodChannel = FlutterMethodChannel(
        name: "polar/methods", binaryMessenger: registrar.messenger())
      let eventChannel = FlutterEventChannel(
        name: "polar/events", binaryMessenger: registrar.messenger())
      let searchChannel = FlutterEventChannel(
      name: "polar/search", binaryMessenger: registrar.messenger())

    let instance = SwiftPolarPlugin(
      messenger: registrar.messenger(),
      methodChannel: methodChannel,
      eventChannel: eventChannel,
      searchChannel: searchChannel
    )

    registrar.addMethodCallDelegate(instance, channel: methodChannel)
    eventChannel.setStreamHandler(instance)
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
      case "doRestart":
        doRestart(call, result)
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
      case "getLocalTime":
        getLocalTime(call, result)
      case "setLocalTime":
        setLocalTime(call, result)
      case "doFirstTimeUse":
        doFirstTimeUse(call, result)
      case "isFtuDone":
        isFtuDone(call, result)
      case "deleteStoredDeviceData":
        deleteStoredDeviceData(call, result)
      case "deleteDeviceDateFolders":
        deleteDeviceDateFolders(call, result)
      case "getSteps":
        getSteps(call, result)
      case "getDistance":
        getDistance(call, result)
      case "getActiveTime":
        getActiveTime(call, result)
      case "getActivitySampleData":
        getActivitySampleData(call, result)
      case "sendInitializationAndStartSyncNotifications":
        sendInitializationAndStartSyncNotifications(call, result)
      case "sendTerminateAndStopSyncNotifications":
        sendTerminateAndStopSyncNotifications(call, result)
      default: result(FlutterMethodNotImplemented)
      }
    } catch {
      result(
        FlutterError(
          code: "Error in Polar plugin", message: error.localizedDescription, details: nil))
    }
  }
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
      -> FlutterError?
    {
      initApi()
      self.events = events
      return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
      events = nil
      return nil
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
    let identifier = call.arguments as! String
    _ = api.doFactoryReset(identifier)
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

  func doRestart(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let identifier = call.arguments as! String
    _ = api.doRestart(identifier)
      .subscribe(
        onCompleted: {
          result(nil)
        },
        onError: { error in
          result(
            FlutterError(
              code: "Error doing restart", message: error.localizedDescription, details: nil))
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

private func success(_ event: String, data: Any? = nil) {
    DispatchQueue.main.async {
        self.events?(["event": event, "data": data])
    }
  }

  public func deviceConnecting(_ polarDeviceInfo: PolarDeviceInfo) {
    guard let data = jsonEncode(PolarDeviceInfoCodable(polarDeviceInfo))
    else {
      return
    }
    success("deviceConnecting", data: data)
  }

  public func deviceConnected(_ polarDeviceInfo: PolarDeviceInfo) {
    guard let data = jsonEncode(PolarDeviceInfoCodable(polarDeviceInfo))
    else {
      return
    }
    success("deviceConnected", data: data)
  }

  public func deviceDisconnected(_ polarDeviceInfo: PolarDeviceInfo, pairingError: Bool) {
    guard let data = jsonEncode(PolarDeviceInfoCodable(polarDeviceInfo))
    else {
      return
    }
    success("deviceDisconnected", data: [data, pairingError])
  }

  public func batteryLevelReceived(_ identifier: String, batteryLevel: UInt) {
    success("batteryLevelReceived", data: [identifier, batteryLevel])
  }

  public func batteryChargingStatusReceived(
    _ identifier: String, chargingStatus: BleBasClient.ChargeState
  ) {
    success(
      "batteryChargingStatusReceived", data: [identifier, String(describing: chargingStatus)])
  }

  public func blePowerOn() {
    success("blePowerStateChanged", data: true)
  }

  public func blePowerOff() {
    success("blePowerStateChanged", data: true)
  }

  public func bleSdkFeatureReady(_ identifier: String, feature: PolarBleSdkFeature) {
      success(
      "sdkFeatureReady",
      data: [
        identifier,
        PolarBleSdkFeature.allCases.firstIndex(of: feature)!,
      ])
  }

  public func disInformationReceived(_ identifier: String, uuid: CBUUID, value: String) {
      success(
      "disInformationReceived", data: [identifier, uuid.uuidString, value])
  }

  public func disInformationReceivedWithKeysAsStrings(
    _ identifier: String, key: String, value: String
  ) {
      success("disInformationReceived", data: [identifier, key, value])
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

  func getAvailableOfflineRecordingDataTypes(
    _ call: FlutterMethodCall, _ result: @escaping FlutterResult
  ) {
    guard let identifier = call.arguments as? String else {
      result(
        FlutterError(code: "INVALID_ARGUMENT", message: "Identifier is not a string", details: nil))
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
        result(
          FlutterError(
            code: "ERROR_GETTING_DATA_TYPES",
            message: error.localizedDescription,
            details: nil
          ))
      }
    )
  }

  func requestOfflineRecordingSettings(_ call: FlutterMethodCall, _ result: @escaping FlutterResult)
  {
    guard let arguments = call.arguments as? [Any] else {
      result(
        FlutterError(
          code: "INVALID_ARGUMENT", message: "Arguments are not in expected format", details: nil))
      return
    }
    guard let identifier = arguments[0] as? String else {
      result(
        FlutterError(
          code: "INVALID_IDENTIFIER", message: "Identifier is not a string", details: nil))
      return
    }
    guard let index = arguments[1] as? Int, index < PolarDeviceDataType.allCases.count else {
      result(
        FlutterError(
          code: "INVALID_FEATURE", message: "Feature index is out of bounds", details: nil))
      return
    }
    let feature = PolarDeviceDataType.allCases[index]

    _ = api.requestStreamSettings(identifier, feature: feature)
      .subscribe(
        onSuccess: { settings in
          if let encodedData = jsonEncode(PolarSensorSettingCodable(settings)) {
            result(encodedData)
          } else {
            result(
              FlutterError(
                code: "ENCODING_ERROR", message: "Failed to encode stream settings", details: nil))
          }
        },
        onFailure: { error in
          result(
            FlutterError(
              code: "REQUEST_ERROR",
              message: "Error requesting stream settings: \(error.localizedDescription)",
              details: nil))
        })
  }

  func startOfflineRecording(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let arguments = call.arguments as! [Any]
    let identifier = arguments[0] as! String
    let feature = PolarDeviceDataType.allCases[arguments[1] as! Int]
    // Attempt to decode the sensor settings
    let settingsData = arguments[2] as? String
    let settings =
      settingsData != nil
      ? try? decoder.decode(
        PolarSensorSettingCodable.self,
        from: settingsData!.data(using: .utf8)!
      ).data : nil

    _ = api.startOfflineRecording(identifier, feature: feature, settings: settings, secret: nil)
      .subscribe(
        onCompleted: {
          result(nil)
        },
        onError: { error in
          result(
            FlutterError(
              code: "Error starting offline recording", message: error.localizedDescription,
              details: nil))
        })
  }

  func stopOfflineRecording(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {

    let arguments = call.arguments as! [Any]
    let identifier = arguments[0] as! String
    let feature = PolarDeviceDataType.allCases[arguments[1] as! Int]

    api.stopOfflineRecording(identifier, feature: feature).subscribe(
      onCompleted: {

        result(nil)

      },
      onError: { error in

        result(
          FlutterError(
            code: "Error stopping offline recording",
            message: error.localizedDescription.description, details: nil))
      })
  }

  func getOfflineRecordingStatus(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let arguments = call.arguments as! [Any]
    let identifier = arguments[0] as! String

    _ = api.getOfflineRecordingStatus(identifier)
      .subscribe(
        onSuccess: { statusDict in
          // Filter and map keys where the value is true
          let keysWithTrueValues = statusDict.compactMap { key, value -> Int? in
            value ? PolarDeviceDataType.allCases.firstIndex(of: key) : nil
          }
          result(keysWithTrueValues)  // Return only the filtered list of keys
        },
        onFailure: { error in
          result(
            FlutterError(
              code: "Error getting offline recording status", message: error.localizedDescription,
              details: nil)
          )
        })
  }

  func listOfflineRecordings(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    guard let identifier = call.arguments as? String else {
      result(
        FlutterError(
          code: "INVALID_ARGUMENTS", message: "Expected a string identifier as argument",
          details: nil))
      return
    }

    api.listOfflineRecordings(identifier).debug("listOfflineRecordings")
      .toArray()
      .subscribe(
        onSuccess: { entries in
          var jsonStringList: [String] = []

          do {
            encoder.dateEncodingStrategy = .iso8601
            for entry in entries {
              // Use PolarOfflineRecordingEntryCodable for encoding
              let entryCodable = PolarOfflineRecordingEntryCodable(entry)
              let data = try encoder.encode(entryCodable)
              if let jsonString = String(data: data, encoding: .utf8) {
                jsonStringList.append(jsonString)
              }
            }
            result(jsonStringList)  // Return the array of JSON strings
          } catch {
            result(
              FlutterError(
                code: "ENCODE_ERROR", message: "Failed to encode entries to JSON", details: nil))
          }
        },
        onFailure: { error in
          result(
            FlutterError(
              code: "ERROR",
              message: "Offline recording listing error: \(error.localizedDescription)",
              details: nil))
        }
      )
  }

  func getOfflineRecord(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let arguments = call.arguments as! [Any]
    let identifier = arguments[0] as! String
    let entryJsonString = arguments[1] as! String

    guard let entryData = entryJsonString.data(using: .utf8) else {
      result(
        FlutterError(code: "INVALID_ARGUMENT", message: "Invalid entry JSON string", details: nil))
      return
    }

    do {
      let entry = try JSONDecoder().decode(PolarOfflineRecordingEntryCodable.self, from: entryData)
        .data

      _ = api.getOfflineRecord(identifier, entry: entry, secret: nil)
        .subscribe(
          onSuccess: { recordingData in
            do {
              // Use the PolarOfflineRecordingDataCodable to encode the data to JSON
              let dataCodable = PolarOfflineRecordingDataCodable(recordingData)
              encoder.dateEncodingStrategy = .millisecondsSince1970
              let data = try encoder.encode(dataCodable)
              if let jsonString = String(data: data, encoding: .utf8) {
                result(jsonString)
              } else {
                result(
                  FlutterError(
                    code: "ENCODE_ERROR", message: "Failed to encode recording data to JSON string",
                    details: nil))
              }
            } catch {
              result(
                FlutterError(
                  code: "ENCODE_ERROR", message: "Failed to encode recording data to JSON",
                  details: nil))
            }
          },
          onFailure: { error in
            result(
              FlutterError(
                code: "FETCH_ERROR",
                message: "Failed to fetch recording: \(error.localizedDescription)", details: nil))
          }
        )
    } catch {
      result(
        FlutterError(code: "DECODE_ERROR", message: "Failed to decode entry JSON", details: nil))
    }
  }

  func removeOfflineRecord(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let arguments = call.arguments as! [Any]
    let identifier = arguments[0] as! String
    let entryJsonString = arguments[1] as! String

    guard let entryData = entryJsonString.data(using: .utf8) else {
      result(
        FlutterError(code: "INVALID_ARGUMENT", message: "Invalid entry JSON string", details: nil))
      return
    }

    do {
      let entry = try! JSONDecoder().decode(PolarOfflineRecordingEntryCodable.self, from: entryData)
        .data

      _ = api.removeOfflineRecord(identifier, entry: entry).subscribe(
        onCompleted: {
          result(nil)
        },
        onError: { error in
          result(
            FlutterError(
              code: "Error removing exercise", message: error.localizedDescription, details: nil))
        })
    }
  }

  func getDiskSpace(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let identifier = call.arguments as! String
    _ = api.getDiskSpace(identifier).subscribe(
      onSuccess: { diskSpaceData in
        let freeSpace = diskSpaceData.freeSpace  // Corrected from 'availableSpace'
        let totalSpace = diskSpaceData.totalSpace
        result([freeSpace, totalSpace])  // Return as a list
      },
      onFailure: { error in
        result(
          FlutterError(
            code: "Error getting disk space", message: error.localizedDescription, details: nil))
      })
  }

  func getLocalTime(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    guard let identifier = call.arguments as? String else {
      result(
        FlutterError(
          code: "INVALID_ARGUMENTS", message: "Expected a device identifier as a String",
          details: nil))
      return
    }

    _ = api.getLocalTime(identifier).subscribe(
      onSuccess: { time in
        let dateFormatter = ISO8601DateFormatter()
        let timeString = dateFormatter.string(from: time)

        result(timeString)
      },
      onFailure: { error in
        result(
          FlutterError(
            code: "GET_LOCAL_TIME_ERROR",
            message: error.localizedDescription,
            details: nil
          )
        )
      })
  }

  func setLocalTime(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    guard let args = call.arguments as? [Any],
      args.count == 2,
      let identifier = args[0] as? String,
      let timestamp = args[1] as? Double
    else {
      result(
        FlutterError(
          code: "INVALID_ARGUMENTS", message: "Expected [identifier, timestamp] as arguments",
          details: nil))
      return
    }

    let time = Date(timeIntervalSince1970: timestamp)

    let timeZone = TimeZone.current

    _ = api.setLocalTime(identifier, time: time, zone: timeZone).subscribe(
      onCompleted: {
        result(nil)
      },
      onError: { error in
        result(
          FlutterError(
            code: "SET_LOCAL_TIME_ERROR",
            message: error.localizedDescription,
            details: nil
          )
        )
      }
    )
  }

  func doFirstTimeUse(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
      let identifier = args["identifier"] as? String,
      let configDict = args["config"] as? [String: Any]
    else {
      result(
        FlutterError(
          code: "INVALID_ARGUMENTS",
          message: "Expected identifier and config dictionary",
          details: nil))
      return
    }

    // Convert the dictionary to PolarFirstTimeUseConfig
    guard let gender = configDict["gender"] as? String,
      let birthDateString = configDict["birthDate"] as? String,
      let height = configDict["height"] as? Int,
      let weight = configDict["weight"] as? Int,
      let maxHeartRate = configDict["maxHeartRate"] as? Int,
      let vo2Max = configDict["vo2Max"] as? Int,
      let restingHeartRate = configDict["restingHeartRate"] as? Int,
      let trainingBackground = configDict["trainingBackground"] as? Int,
      let deviceTime = configDict["deviceTime"] as? String,
      let typicalDay = configDict["typicalDay"] as? Int,
      let sleepGoalMinutes = configDict["sleepGoalMinutes"] as? Int
    else {
      result(
        FlutterError(
          code: "INVALID_CONFIG",
          message: "Invalid configuration parameters",
          details: nil))
      return
    }

    // Convert string date to Date object
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    guard let birthDate = dateFormatter.date(from: birthDateString) else {
      result(
        FlutterError(
          code: "INVALID_DATE",
          message: "Invalid birth date format",
          details: nil))
      return
    }

    // Convert training background value to appropriate enum case
    let trainingBackgroundLevel: PolarFirstTimeUseConfig.TrainingBackground
    switch trainingBackground {
    case 10: trainingBackgroundLevel = .occasional
    case 20: trainingBackgroundLevel = .regular
    case 30: trainingBackgroundLevel = .frequent
    case 40: trainingBackgroundLevel = .heavy
    case 50: trainingBackgroundLevel = .semiPro
    case 60: trainingBackgroundLevel = .pro
    default: trainingBackgroundLevel = .occasional  // default fallback
    }

    // Convert typical day to enum
    let typicalDayEnum: PolarFirstTimeUseConfig.TypicalDay
    switch typicalDay {
    case 1: typicalDayEnum = .mostlyMoving
    case 2: typicalDayEnum = .mostlySitting
    case 3: typicalDayEnum = .mostlyStanding
    default: typicalDayEnum = .mostlySitting
    }

    // Create config object with validation
    let config = PolarBleSdk.PolarFirstTimeUseConfig(
      gender: gender == "Male" ? .male : .female,
      birthDate: birthDate,
      height: Float(height),
      weight: Float(weight),
      maxHeartRate: maxHeartRate,
      vo2Max: vo2Max,
      restingHeartRate: restingHeartRate,
      trainingBackground: trainingBackgroundLevel,
      deviceTime: deviceTime,
      typicalDay: typicalDayEnum,
      sleepGoalMinutes: sleepGoalMinutes
    )

    _ = api.doFirstTimeUse(identifier, ftuConfig: config).subscribe(
      onCompleted: {
        result(nil)
      },
      onError: { error in
        result(
          FlutterError(
            code: "FTU_ERROR",
            message: error.localizedDescription,
            details: nil
          ))
      }
    )
  }

  func isFtuDone(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    guard let identifier = call.arguments as? String else {
      result(
        FlutterError(
          code: "INVALID_ARGUMENTS",
          message: "Expected a device identifier as a String",
          details: nil
        ))
      return
    }

    _ = api.isFtuDone(identifier).subscribe(
      onSuccess: { isFtuDone in
        result(isFtuDone)
      },
      onFailure: { error in
        result(
          FlutterError(
            code: "FTU_CHECK_ERROR",
            message: error.localizedDescription,
            details: nil
          )
        )
      }
    )
  }

  func deleteStoredDeviceData(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [Any],
          arguments.count == 3,
          let identifier = arguments[0] as? String,
          let dataTypeIndex = arguments[1] as? Int,
          let untilDateString = arguments[2] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENTS",
                          message: "Expected [identifier, dataType, untilDate]",
                          details: nil))
        return
    }

    // Convert dataType index to PolarStoredDataType
    guard dataTypeIndex < PolarBleSdk.PolarStoredDataType.StoredDataType.allCases.count else {
        result(FlutterError(code: "INVALID_DATA_TYPE",
                          message: "Invalid data type index",
                          details: nil))
        return
    }
    let dataType = PolarBleSdk.PolarStoredDataType.StoredDataType.allCases[dataTypeIndex]

    // Parse the until date
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    guard let untilDate = dateFormatter.date(from: untilDateString) else {
        result(FlutterError(code: "INVALID_DATE_FORMAT",
                          message: "Date must be in yyyy-MM-dd format",
                          details: nil))
        return
    }

    _ = api.deleteStoredDeviceData(identifier, dataType: dataType, until: untilDate)
        .subscribe(
            onCompleted: {
                result(nil)
            },
            onError: { error in
                result(FlutterError(code: "ERROR_DELETING_DATA",
                                  message: error.localizedDescription,
                                  details: nil))
            }
        )
  }

  func deleteDeviceDateFolders(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [Any],
          arguments.count == 3,
          let identifier = arguments[0] as? String,
          let fromDateString = arguments[1] as? String,
          let toDateString = arguments[2] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENTS",
                          message: "Expected [identifier, fromDate, toDate]",
                          details: nil))
        return
    }

    // Parse the dates
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    
    guard let fromDate = dateFormatter.date(from: fromDateString),
          let toDate = dateFormatter.date(from: toDateString) else {
        result(FlutterError(code: "INVALID_DATE_FORMAT",
                          message: "Dates must be in yyyy-MM-dd format",
                          details: nil))
        return
    }

    _ = api.deleteDeviceDateFolders(identifier, fromDate: fromDate, toDate: toDate)
        .subscribe(
            onCompleted: {
                result(nil)
            },
            onError: { error in
                result(FlutterError(code: "ERROR_DELETING_FOLDERS",
                                  message: error.localizedDescription,
                                  details: nil))
            }
        )
  }

  func getSteps(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [Any],
              arguments.count == 3,
              let identifier = arguments[0] as? String,
              let fromDateString = arguments[1] as? String,
              let toDateString = arguments[2] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS",
                              message: "Expected [identifier, fromDate, toDate]",
                              details: nil))
            return
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let fromDate = dateFormatter.date(from: fromDateString),
              let toDate = dateFormatter.date(from: toDateString) else {
            result(FlutterError(code: "INVALID_DATE_FORMAT",
                              message: "Dates must be in yyyy-MM-dd format",
                              details: nil))
            return
        }

        _ = api.getSteps(identifier: identifier, fromDate: fromDate, toDate: toDate)
            .subscribe(
                onSuccess: { stepsData in
                    do {
                        let encoder = JSONEncoder()
                        encoder.dateEncodingStrategy = .iso8601
                        let jsonData = try encoder.encode(stepsData)
                        if let jsonString = String(data: jsonData, encoding: .utf8) {
                            result(jsonString)
                        } else {
                            result(FlutterError(code: "ENCODING_ERROR",
                                              message: "Failed to convert JSON data to string",
                                              details: nil))
                        }
                    } catch {
                        result(FlutterError(code: "ENCODING_ERROR",
                                          message: "Failed to encode steps data: \(error.localizedDescription)",
                                          details: nil))
                    }
                },
                onFailure: { error in
                    result(FlutterError(code: "ERROR_GETTING_STEPS",
                                      message: error.localizedDescription,
                                      details: nil))
                }
            )
    }

  func getDistance(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [Any],
              arguments.count == 3,
              let identifier = arguments[0] as? String,
              let fromDateString = arguments[1] as? String,
              let toDateString = arguments[2] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS",
                              message: "Expected [identifier, fromDate, toDate]",
                              details: nil))
            return
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let fromDate = dateFormatter.date(from: fromDateString),
              let toDate = dateFormatter.date(from: toDateString) else {
            result(FlutterError(code: "INVALID_DATE_FORMAT",
                              message: "Dates must be in yyyy-MM-dd format",
                              details: nil))
            return
        }

        _ = api.getDistance(identifier: identifier, fromDate: fromDate, toDate: toDate)
            .subscribe(
                onSuccess: { distanceData in
                    do {
                        let encoder = JSONEncoder()
                        encoder.dateEncodingStrategy = .iso8601
                        let codables = distanceData.map(PolarDistanceDataCodable.init)
                        let jsonData = try encoder.encode(codables)
                        if let jsonString = String(data: jsonData, encoding: .utf8) {
                            result(jsonString)
                        } else {
                            result(FlutterError(code: "ENCODING_ERROR",
                                              message: "Failed to convert JSON data to string",
                                              details: nil))
                        }
                    } catch {
                        result(FlutterError(code: "ENCODING_ERROR",
                                          message: "Failed to encode distance data: \(error.localizedDescription)",
                                          details: nil))
                    }
                },
                onFailure: { error in
                    result(FlutterError(code: "ERROR_GETTING_DISTANCE",
                                      message: error.localizedDescription,
                                      details: nil))
                }
            )
    }

  func getActiveTime(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [Any],
              arguments.count == 3,
              let identifier = arguments[0] as? String,
              let fromDateString = arguments[1] as? String,
              let toDateString = arguments[2] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS",
                              message: "Expected [identifier, fromDate, toDate]",
                              details: nil))
            return
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let fromDate = dateFormatter.date(from: fromDateString),
              let toDate = dateFormatter.date(from: toDateString) else {
            result(FlutterError(code: "INVALID_DATE_FORMAT",
                              message: "Dates must be in yyyy-MM-dd format",
                              details: nil))
            return
        }

        _ = api.getActiveTime(identifier: identifier, fromDate: fromDate, toDate: toDate)
            .subscribe(
                onSuccess: { activeTimeData in
                    do {
                        let encoder = JSONEncoder()
                        encoder.dateEncodingStrategy = .iso8601
                        let codables = activeTimeData.map(PolarActiveTimeDataCodable.init)
                        let jsonData = try encoder.encode(codables)
                        if let jsonString = String(data: jsonData, encoding: .utf8) {
                            result(jsonString)
                        } else {
                            result(FlutterError(code: "ENCODING_ERROR",
                                              message: "Failed to convert JSON data to string",
                                              details: nil))
                        }
                    } catch {
                        result(FlutterError(code: "ENCODING_ERROR",
                                          message: "Failed to encode active time data: \(error.localizedDescription)",
                                          details: nil))
                    }
                },
                onFailure: { error in
                    result(FlutterError(code: "ERROR_GETTING_ACTIVE_TIME",
                                      message: error.localizedDescription,
                                      details: nil))
                }
            )
    }

  func getActivitySampleData(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [Any],
              arguments.count == 3,
              let identifier = arguments[0] as? String,
              let fromDateString = arguments[1] as? String,
              let toDateString = arguments[2] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS",
                              message: "Expected [identifier, fromDate, toDate]",
                              details: nil))
            return
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let fromDate = dateFormatter.date(from: fromDateString),
              let toDate = dateFormatter.date(from: toDateString) else {
            result(FlutterError(code: "INVALID_DATE_FORMAT",
                              message: "Dates must be in yyyy-MM-dd format",
                              details: nil))
            return
        }

        _ = api.getActivitySampleData(identifier: identifier, fromDate: fromDate, toDate: toDate)
            .subscribe(
                onSuccess: { activityDayDataList in
                    do {
                        // Convert the data directly from the native structures
                        let response = activityDayDataList.map { dayData -> [String: Any] in
                            let samplesDataList = dayData.polarActivityDataList.compactMap { activityData -> [String: Any]? in
                                // Access the samples directly from the activityData
                                guard let samples = activityData.samples else { return nil }
                                
                                // Convert startTime to ISO8601 string
                                let formatter = ISO8601DateFormatter()
                                let startTimeString = formatter.string(from: samples.startTime)
                                
                                // Convert activityInfoList
                                let activityInfoList = samples.activityInfoList.map { activityInfo in
                                    [
                                        "timeStamp": formatter.string(from: activityInfo.timeStamp),
                                        "activityClass": activityInfo.activityClass.rawValue,
                                        "factor": activityInfo.factor
                                    ]
                                }
                                
                                return [
                                    "startTime": startTimeString,
                                    "metRecordingInterval": samples.metRecordingInterval,
                                    "metSamples": samples.metSamples ?? [],
                                    "stepRecordingInterval": samples.stepRecordingInterval,
                                    "stepSamples": samples.stepSamples ?? [],
                                    "activityInfoList": activityInfoList
                                ]
                            }
                            
                            // Extract date string from first sample's startTime
                            let dateString: String
                            if let firstSample = samplesDataList.first,
                               let startTime = firstSample["startTime"] as? String,
                               !startTime.isEmpty {
                                // Extract date part from ISO8601 string (YYYY-MM-DD)
                                if let dateRange = startTime.range(of: "T") {
                                    dateString = String(startTime[..<dateRange.lowerBound])
                                } else {
                                    dateString = startTime
                                }
                            } else {
                                dateString = ""
                            }
                            
                            return [
                                "date": dateString,
                                "samplesDataList": samplesDataList
                            ]
                        }
                        
                        let jsonData = try JSONSerialization.data(withJSONObject: response, options: [])
                        if let jsonString = String(data: jsonData, encoding: .utf8) {
                            result(jsonString)
                        } else {
                            result(FlutterError(code: "ENCODING_ERROR",
                                              message: "Failed to convert JSON data to string",
                                              details: nil))
                        }
                    } catch {
                        result(FlutterError(code: "ENCODING_ERROR",
                                          message: "Failed to encode activity sample data: \(error.localizedDescription)",
                                          details: nil))
                    }
                },
                onFailure: { error in
                    result(FlutterError(code: "ERROR_GETTING_ACTIVITY_SAMPLE_DATA",
                                      message: error.localizedDescription,
                                      details: nil))
                }
            )
    }

  func sendInitializationAndStartSyncNotifications(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    guard let identifier = call.arguments as? String else {
      result(FlutterError(code: "ERROR_INVALID_ARGUMENT",
                        message: "Expected a single String argument",
                        details: nil))
      return
    }

    _ = api.sendInitializationAndStartSyncNotifications(identifier: identifier)
      .subscribe(
        onCompleted: {
          result(nil)
        },
        onError: { error in
          result(FlutterError(code: error.localizedDescription,
                            message: error.localizedDescription,
                            details: nil))
        }
      )
  }

  func sendTerminateAndStopSyncNotifications(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    guard let identifier = call.arguments as? String else {
      result(FlutterError(code: "ERROR_INVALID_ARGUMENT",
                        message: "Expected a single String argument",
                        details: nil))
      return
    }

    _ = api.sendTerminateAndStopSyncNotifications(identifier: identifier)
      .subscribe(
        onCompleted: {
          result(nil)
        },
        onError: { error in
          result(FlutterError(code: error.localizedDescription,
                            message: error.localizedDescription,
                            details: nil))
        }
      )
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
    case .skinTemperature:
        stream = api.startSkinTemperatureStreaming(identifier, settings: settings!)
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
