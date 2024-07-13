//
//  Codables.swift
//  polar
//
//  Created by Aaron DeLory on 6/4/21.
//

import Foundation
import PolarBleSdk

class PolarDeviceInfoCodable: Encodable {
    let data: PolarDeviceInfo

    required init(_ data: PolarBleSdk.PolarDeviceInfo) {
        self.data = data
    }

    enum CodingKeys: String, CodingKey {
        case deviceId
        case address
        case rssi
        case name
        case connectable
    }

    func encode(to encoder: Encoder) {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encode(data.deviceId, forKey: .deviceId)
        try? container.encode(data.address, forKey: .address)
        try? container.encode(data.rssi, forKey: .rssi)
        try? container.encode(data.name, forKey: .name)
        try? container.encode(data.connectable, forKey: .connectable)
    }
}

class PolarDataCodable<T>: Encodable {
    let data: T

    required init(_ data: T) {
        self.data = data
    }

    enum CodingKeys: String, CodingKey {
        case samples
        case type
    }

    func encode(to encoder: Encoder) {
        var container = encoder.container(keyedBy: CodingKeys.self)

        let codables: [Encodable]
        if let data = data as? PolarHrData {
            codables = data.map(PolarHrSampleCodable.init)
        } else if let data = data as? PolarEcgData {
            codables = data.samples.map(PolarEcgSampleCodable.init)
        } else if let data = data as? PolarAccData {
            codables = data.samples.map(PolarAccSampleCodable.init)
        } else if let data = data as? PolarPpgData {
            try? container.encode(data.type.rawValue, forKey: .type)
            codables = data.samples.map(PolarPpgSampleCodable.init)
        } else if let data = data as? PolarPpiData {
            codables = data.samples.map(PolarPpiSampleCodable.init)
        } else if let data = data as? PolarGyroData {
            codables = data.samples.map(PolarGyroSampleCodable.init)
        } else if let data = data as? PolarMagnetometerData {
            codables = data.samples.map(PolarMagnetometerSampleCodable.init)
        // } else if let data = data as? PolarOfflineRecordingEntry {
        //     codables = [PolarOfflineRecordingEntryCodable(data)]
        } else {
            codables = []
        }

        try? container.encode(codables.wrap(), forKey: .samples)
    }
}

typealias PolarHrSample = (hr: UInt8, rrsMs: [Int], rrAvailable: Bool, contactStatus: Bool, contactStatusSupported: Bool)

class PolarHrSampleCodable: Encodable {
    let data: PolarHrSample

    required init(_ data: PolarHrSample) {
        self.data = data
    }

    enum CodingKeys: String, CodingKey {
        case hr
        case rrsMs
        case rrAvailable
        case contactStatus
        case contactStatusSupported
    }

    func encode(to encoder: Encoder) {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encode(data.hr, forKey: .hr)
        try? container.encode(data.rrsMs, forKey: .rrsMs)
        try? container.encode(data.rrAvailable, forKey: .rrAvailable)
        try? container.encode(data.contactStatus, forKey: .contactStatus)
        try? container.encode(data.contactStatusSupported, forKey: .contactStatusSupported)
    }
}

typealias PolarEcgSample = (timeStamp: UInt64, voltage: Int32)

class PolarEcgSampleCodable: Encodable {
    let data: PolarEcgSample

    init(_ data: PolarEcgSample) {
        self.data = data
    }

    enum CodingKeys: String, CodingKey {
        case timeStamp
        case voltage
    }

    func encode(to encoder: Encoder) {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encode(data.timeStamp, forKey: .timeStamp)
        try? container.encode(data.voltage, forKey: .voltage)
    }
}

typealias PolarAccSample = (timeStamp: UInt64, x: Int32, y: Int32, z: Int32)

class PolarAccSampleCodable: Encodable {
    let data: PolarAccSample

    init(_ data: PolarAccSample) {
        self.data = data
    }

    enum CodingKeys: String, CodingKey {
        case timeStamp
        case x
        case y
        case z
    }

    func encode(to encoder: Encoder) {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encode(data.timeStamp, forKey: .timeStamp)
        try? container.encode(data.x, forKey: .x)
        try? container.encode(data.y, forKey: .y)
        try? container.encode(data.z, forKey: .z)
    }
}






class PolarExerciseDataCodable: Encodable {
    let data: PolarExerciseData

    init(_ data: PolarExerciseData) {
        self.data = data
    }

    enum CodingKeys: String, CodingKey {
        case interval
        case samples
    }

    func encode(to encoder: Encoder) {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encode(data.interval, forKey: .interval)
        try? container.encode(data.samples, forKey: .samples)
    }
}

typealias PolarGyroSample = (timeStamp: UInt64, x: Float, y: Float, z: Float)

class PolarGyroSampleCodable: Encodable {
    let data: PolarGyroSample

    init(_ data: PolarGyroSample) {
        self.data = data
    }

    enum CodingKeys: String, CodingKey {
        case timeStamp
        case x
        case y
        case z
    }

    func encode(to encoder: Encoder) {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encode(data.timeStamp, forKey: .timeStamp)
        try? container.encode(data.x, forKey: .x)
        try? container.encode(data.y, forKey: .y)
        try? container.encode(data.z, forKey: .z)
    }
}

typealias PolarMagnetometerSample = (timeStamp: UInt64, x: Float, y: Float, z: Float)

class PolarMagnetometerSampleCodable: Encodable {
    let data: PolarMagnetometerSample

    init(_ data: PolarMagnetometerSample) {
        self.data = data
    }

    enum CodingKeys: String, CodingKey {
        case timeStamp
        case x
        case y
        case z
    }

    func encode(to encoder: Encoder) {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encode(data.timeStamp, forKey: .timeStamp)
        try? container.encode(data.x, forKey: .x)
        try? container.encode(data.y, forKey: .y)
        try? container.encode(data.z, forKey: .z)
    }
}

typealias PolarPpgSample = (timeStamp: UInt64, channelSamples: [Int32])

class PolarPpgSampleCodable: Encodable {
    let data: PolarPpgSample

    init(_ data: PolarPpgSample) {
        self.data = data
    }

    enum CodingKeys: String, CodingKey {
        case timeStamp
        case channelSamples
    }

    func encode(to encoder: Encoder) {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encode(data.timeStamp, forKey: .timeStamp)
        try? container.encode(data.channelSamples, forKey: .channelSamples)
    }
}

typealias PolarPpiSample = (hr: Int, ppInMs: UInt16, ppErrorEstimate: UInt16, blockerBit: Int, skinContactStatus: Int, skinContactSupported: Int)

class PolarPpiSampleCodable: Encodable {
    let data: PolarPpiSample

    init(_ data: PolarPpiSample) {
        self.data = data
    }

    enum CodingKeys: String, CodingKey {
        case hr
        case ppInMs
        case ppErrorEstimate
        case blockerBit
        case skinContactStatus
        case skinContactSupported
    }

    func encode(to encoder: Encoder) {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encode(data.hr, forKey: .hr)
        try? container.encode(data.ppInMs, forKey: .ppInMs)
        try? container.encode(data.ppErrorEstimate, forKey: .ppErrorEstimate)
        try? container.encode(data.blockerBit, forKey: .blockerBit)
        try? container.encode(data.skinContactStatus, forKey: .skinContactStatus)
        try? container.encode(data.skinContactSupported, forKey: .skinContactSupported)
    }
}


class PolarSensorSettingCodable: Codable {
    let data: PolarSensorSetting

    init(_ data: PolarSensorSetting) {
        self.data = data
    }

    required init(from decoder: Decoder) {
        let container = try? decoder.container(keyedBy: CodingKeys.self)

        // Flutter can only send maps keyed by strings
        let dict: [String: Set<UInt32>] = (try? container?.decode([String: Set<UInt32>].self, forKey: .settings)) ?? [:]
        let newDict = Dictionary(
            uniqueKeysWithValues:
            dict.map { key, value in
                (PolarSensorSetting.SettingType(rawValue: Int(key) ?? -1) ?? PolarSensorSetting.SettingType.unknown, value.first ?? 0)
            }
        )

        data = PolarSensorSetting(newDict)
    }

    enum CodingKeys: String, CodingKey {
        case settings
    }

    func encode(to encoder: Encoder) {
        var container = encoder.container(keyedBy: CodingKeys.self)

        let newDict = Dictionary(
            uniqueKeysWithValues:
            data.settings.map { key, value in (key.rawValue, value) }
        )

        try? container.encode(newDict, forKey: .settings)
    }
}

class PolarExerciseEntryCodable: Codable {
    let data: PolarExerciseEntry

    required init(_ data: PolarExerciseEntry) {
        self.data = data
    }

    required init(from decoder: Decoder) {
        guard let container = try? decoder.container(keyedBy: CodingKeys.self),
              let path = try? container.decode(String.self, forKey: .path),
              let millis = try? container.decode(Int64.self, forKey: .date),
              let entryId = try? container.decode(String.self, forKey: .entryId)
        else {
            data = PolarExerciseEntry(path: "", date: Date(), entryId: "")
            return
        }

        data = PolarExerciseEntry(path: path, date: Date(milliseconds: millis), entryId: entryId)
    }

    enum CodingKeys: String, CodingKey {
        case path
        case date
        case entryId
    }

    func encode(to encoder: Encoder) {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encode(data.path, forKey: .path)
        try? container.encode(data.date.millisecondsSince1970, forKey: .date)
        try? container.encode(data.entryId, forKey: .entryId)
    }
}

class LedConfigCodable: Decodable {
    let data: LedConfig

    required init(from decoder: Decoder) {
        guard let container = try? decoder.container(keyedBy: CodingKeys.self),
              let sdkModeLedEnabled = try? container.decode(Bool.self, forKey: .sdkModeLedEnabled),
              let ppiModeLedEnabled = try? container.decode(Bool.self, forKey: .ppiModeLedEnabled)
        else {
            data = LedConfig(sdkModeLedEnabled: true, ppiModeLedEnabled: true)
            return
        }

        data = LedConfig(sdkModeLedEnabled: sdkModeLedEnabled, ppiModeLedEnabled: ppiModeLedEnabled)
    }

    enum CodingKeys: String, CodingKey {
        case sdkModeLedEnabled
        case ppiModeLedEnabled
    }
}

extension Date {
    var millisecondsSince1970: Int64 {
        Int64((timeIntervalSince1970 * 1000).rounded())
    }

    init(milliseconds: Int64) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    }
}

class PolarOfflineRecordingEntryCodable: Codable {
    var data: PolarOfflineRecordingEntry

    required init(_ data: PolarOfflineRecordingEntry) {
        self.data = data
    }

    enum CodingKeys: String, CodingKey {
        case path
        case size
        case date
        case type
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(data.path, forKey: .path)
        try container.encode(data.size, forKey: .size)
        try container.encode(data.date.timeIntervalSince1970 * 1000, forKey: .date)  // Encode date as milliseconds since epoch
        if let typeIndex = PolarDeviceDataType.allCases.firstIndex(of: data.type) {
                    try container.encode(typeIndex, forKey: .type)  // Encode type as enum index
                } else {
                    throw EncodingError.invalidValue(data.type, EncodingError.Context(codingPath: [CodingKeys.type], debugDescription: "Invalid PolarDeviceDataType"))
                }
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let path = try container.decode(String.self, forKey: .path)
        let size = try container.decode(UInt.self, forKey: .size)
        let dateMillis = try container.decode(Double.self, forKey: .date)
        let date = Date(timeIntervalSince1970: dateMillis / 1000)  // Convert milliseconds back to Date
        let typeIndex = try container.decode(Int.self, forKey: .type)
        let type = PolarDeviceDataType.allCases[typeIndex]

        data = PolarOfflineRecordingEntry(path: path, size: size, date: date, type: type)
    }
}




class PolarEcgDataCodable: Encodable {
    let data: PolarEcgData

    init(_ data: PolarEcgData) {
        self.data = data
    }

    enum CodingKeys: String, CodingKey {
        case timeStamp
        case samples
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(data.timeStamp, forKey: .timeStamp)
        let encodedSamples = data.samples.map { PolarEcgSampleCodable($0) }
        try container.encode(encodedSamples, forKey: .samples)
    }
}
class PolarHrDataCodable: Encodable {
    let data: PolarHrData

    init(_ data: PolarHrData) {
        self.data = data
    }

    enum CodingKeys: String, CodingKey {
        case samples
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let encodedSamples = data.map { PolarHrSampleCodable($0) }
        try container.encode(encodedSamples, forKey: .samples)
    }
}
class PolarAccDataCodable: Encodable {
    let data: PolarAccData

    init(_ data: PolarAccData) {
        self.data = data
    }

    enum CodingKeys: String, CodingKey {
        case timeStamp
        case samples
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(data.timeStamp, forKey: .timeStamp)
        let encodedSamples = data.samples.map { PolarAccSampleCodable($0) }
        try container.encode(encodedSamples, forKey: .samples)
    }
}

class PolarGyroDataCodable: Encodable {
    let data: PolarGyroData

    init(_ data: PolarGyroData) {
        self.data = data
    }

    enum CodingKeys: String, CodingKey {
        case timeStamp
        case samples
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(data.timeStamp, forKey: .timeStamp)
        let encodedSamples = data.samples.map { PolarGyroSampleCodable($0) }
        try container.encode(encodedSamples, forKey: .samples)
    }
}

class PolarMagnetometerDataCodable: Encodable {
    let data: PolarMagnetometerData

    init(_ data: PolarMagnetometerData) {
        self.data = data
    }

    enum CodingKeys: String, CodingKey {
        case timeStamp
        case samples
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(data.timeStamp, forKey: .timeStamp)
        let encodedSamples = data.samples.map { PolarMagnetometerSampleCodable($0) }
        try container.encode(encodedSamples, forKey: .samples)
    }
}

class PolarPpgDataCodable: Encodable {
    let data: PolarPpgData

    init(_ data: PolarPpgData) {
        self.data = data
    }

    enum CodingKeys: String, CodingKey {
        case type
        case samples
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(data.type.rawValue, forKey: .type)
        let encodedSamples = data.samples.map { PolarPpgSampleCodable($0) }
        try container.encode(encodedSamples, forKey: .samples)
    }
}

class PolarPpiDataCodable: Encodable {
    let data: PolarPpiData

    init(_ data: PolarPpiData) {
        self.data = data
    }

    enum CodingKeys: String, CodingKey {
        case timeStamp
        case samples
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(data.timeStamp, forKey: .timeStamp)
        let encodedSamples = data.samples.map { PolarPpiSampleCodable($0) }
        try container.encode(encodedSamples, forKey: .samples)
    }
}

class PolarOfflineRecordingDataCodable: Encodable {
    let data: PolarOfflineRecordingData

    required init(_ data: PolarOfflineRecordingData) {
        self.data = data
    }

    enum CodingKeys: String, CodingKey {
        case type
        case startTime
        case settings
        case accData
        case gyroData
        case magData
        case ppgData
        case ppiData
        case hrData
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch data {
        case .accOfflineRecordingData(let accData, let startTime, let settings):
              if let typeIndex = PolarDeviceDataType.allCases.firstIndex(of: .acc) {
                  try container.encode(typeIndex, forKey: .type)
              }
              try container.encode(startTime.millisecondsSince1970, forKey: .startTime)
              try container.encode(PolarSensorSettingCodable(settings), forKey: .settings)
            
              try container.encode(PolarAccDataCodable(accData), forKey: .accData)
          case .gyroOfflineRecordingData(let gyroData, let startTime, let settings):
              if let typeIndex = PolarDeviceDataType.allCases.firstIndex(of: .gyro) {
                  try container.encode(typeIndex, forKey: .type)
              }
              try container.encode(startTime.millisecondsSince1970, forKey: .startTime)
              try container.encode(PolarSensorSettingCodable(settings), forKey: .settings)
              try container.encode(PolarGyroDataCodable(gyroData), forKey: .gyroData)
          case .magOfflineRecordingData(let magData, let startTime, let settings):
              if let typeIndex = PolarDeviceDataType.allCases.firstIndex(of: .magnetometer) {
                  try container.encode(typeIndex, forKey: .type)
              }
              try container.encode(startTime.millisecondsSince1970, forKey: .startTime)
              try container.encode(PolarSensorSettingCodable(settings), forKey: .settings)
              try container.encode(PolarMagnetometerDataCodable(magData), forKey: .magData)
          case .ppgOfflineRecordingData(let ppgData, let startTime, let settings):
              if let typeIndex = PolarDeviceDataType.allCases.firstIndex(of: .ppg) {
                  try container.encode(typeIndex, forKey: .type)
              }
              try container.encode(startTime.millisecondsSince1970, forKey: .startTime)
              try container.encode(PolarSensorSettingCodable(settings), forKey: .settings)
              try container.encode(PolarPpgDataCodable(ppgData), forKey: .ppgData)
          case .ppiOfflineRecordingData(let ppiData, let startTime):
              if let typeIndex = PolarDeviceDataType.allCases.firstIndex(of: .ppi) {
                  try container.encode(typeIndex, forKey: .type)
              }
              try container.encode(startTime.millisecondsSince1970, forKey: .startTime)
              try container.encode(PolarPpiDataCodable(ppiData), forKey: .ppiData)
          case .hrOfflineRecordingData(let hrData, let startTime):
              if let typeIndex = PolarDeviceDataType.allCases.firstIndex(of: .hr) {
                  try container.encode(typeIndex, forKey: .type)
              }
              try container.encode(startTime.millisecondsSince1970, forKey: .startTime)
            try container.encode(PolarHrDataCodable(hrData), forKey: .hrData)
        }
    }
}
