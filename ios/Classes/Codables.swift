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

class PolarHrDataCodable: Encodable {
    let data: PolarBleApiDeviceHrObserver.PolarHrData

    required init(_ data: PolarBleApiDeviceHrObserver.PolarHrData) {
        self.data = data
    }

    enum CodingKeys: String, CodingKey {
        case hr
        case rrs
        case rrsMs
        case contact
        case contactSupported
    }

    func encode(to encoder: Encoder) {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encode(data.hr, forKey: .hr)
        try? container.encode(data.rrs, forKey: .rrs)
        try? container.encode(data.rrsMs, forKey: .rrsMs)
        try? container.encode(data.contact, forKey: .contact)
        try? container.encode(data.contactSupported, forKey: .contactSupported)
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

    func encode(to encoder: Encoder) {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encode(data.timeStamp, forKey: .timeStamp)
        try? container.encode(data.samples, forKey: .samples)
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

    func encode(to encoder: Encoder) {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encode(data.timeStamp, forKey: .timeStamp)
        try? container.encode(data.samples.map {
            [
                "x": $0.x,
                "y": $0.y,
                "z": $0.z,
            ]
        }, forKey: .samples)
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

class PolarGyroDataCodable: Encodable {
    let data: PolarGyroData

    init(_ data: PolarGyroData) {
        self.data = data
    }

    enum CodingKeys: String, CodingKey {
        case timeStamp
        case samples
    }

    func encode(to encoder: Encoder) {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encode(data.timeStamp, forKey: .timeStamp)
        try? container.encode(data.samples.map {
            [
                "x": $0.x,
                "y": $0.y,
                "z": $0.z,
            ]
        }, forKey: .samples)
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

    func encode(to encoder: Encoder) {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encode(data.timeStamp, forKey: .timeStamp)
        try? container.encode(data.samples.map {
            [
                "x": $0.x,
                "y": $0.y,
                "z": $0.z,
            ]
        }, forKey: .samples)
    }
}

class PolarOhrDataCodable: Encodable {
    let data: PolarOhrData

    init(_ data: PolarOhrData) {
        self.data = data
    }

    enum CodingKeys: String, CodingKey {
        case timeStamp
        case type
        case samples
    }

    func encode(to encoder: Encoder) {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encode(data.timeStamp, forKey: .timeStamp)
        try? container.encode(data.type.rawValue, forKey: .type)
        try? container.encode(data.samples, forKey: .samples)
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

    func encode(to encoder: Encoder) {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encode(data.timeStamp, forKey: .timeStamp)
        try? container.encode(data.samples.map {
            [
                "hr": $0.hr,
                "ppi": Int($0.ppInMs),
                "errorEstimate": Int($0.ppErrorEstimate),
                "blockerBit": $0.blockerBit,
                "skinContactStatus": $0.skinContactStatus,
                "skinContactSupported": $0.skinContactSupported,
            ]
        }, forKey: .samples)
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
        let dict: [String: UInt32] = (try? container?.decode([String: UInt32].self, forKey: .settings)) ?? [:]
        let newDict = Dictionary(
            uniqueKeysWithValues:
            dict.map { key, value in
                (PolarSensorSetting.SettingType(rawValue: Int(key) ?? -1) ?? PolarSensorSetting.SettingType.unknown, value)
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

extension Date {
    var millisecondsSince1970: Int64 {
        Int64((timeIntervalSince1970 * 1000).rounded())
    }

    init(milliseconds: Int64) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    }
}
