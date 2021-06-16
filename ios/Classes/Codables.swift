//
//  Codables.swift
//  polar
//
//  Created by Aaron DeLory on 6/4/21.
//

import Foundation
import PolarBleSdk

class PolarDeviceInfoCodable: Encodable {
    let polarDeviceInfo: PolarDeviceInfo
    
    init(_ polarDeviceInfo: PolarDeviceInfo) {
        self.polarDeviceInfo = polarDeviceInfo
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
        try? container.encode(polarDeviceInfo.deviceId, forKey: .deviceId)
        try? container.encode(polarDeviceInfo.address, forKey: .address)
        try? container.encode(polarDeviceInfo.rssi, forKey: .rssi)
        try? container.encode(polarDeviceInfo.name, forKey: .name)
        try? container.encode(polarDeviceInfo.connectable, forKey: .connectable)
    }
}

class PolarHrDataCodable: Encodable {
    let polarHrData: PolarBleApiDeviceHrObserver.PolarHrData
    
    init(_ polarHrData: PolarBleApiDeviceHrObserver.PolarHrData) {
        self.polarHrData = polarHrData
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
        try? container.encode(polarHrData.hr, forKey: .hr)
        try? container.encode(polarHrData.rrs, forKey: .rrs)
        try? container.encode(polarHrData.rrsMs, forKey: .rrsMs)
        try? container.encode(polarHrData.contact, forKey: .contact)
        try? container.encode(polarHrData.contactSupported, forKey: .contactSupported)
    }
}

class PolarEcgDataCodable: Encodable {
    let polarEcgData: PolarEcgData
    
    init(_ polarEcgData: PolarEcgData) {
        self.polarEcgData = polarEcgData
    }
    
    enum CodingKeys: String, CodingKey {
        case timeStamp
        case samples
    }
    
    func encode(to encoder: Encoder) {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encode(polarEcgData.timeStamp, forKey: .timeStamp)
        try? container.encode(polarEcgData.samples, forKey: .samples)
    }
}

class PolarAccDataCodable: Encodable {
    let polarAccData: PolarAccData
    
    init(_ polarAccData: PolarAccData) {
        self.polarAccData = polarAccData
    }
    
    enum CodingKeys: String, CodingKey {
        case timeStamp
        case samples
    }
    
    func encode(to encoder: Encoder) {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encode(polarAccData.timeStamp, forKey: .timeStamp)
        try? container.encode(polarAccData.samples.map {
            [
                "x": $0.x,
                "y": $0.y,
                "z": $0.z
            ]
        }, forKey: .samples)
    }
}

class PolarExerciseDataCodable: Encodable {
    let polarExerciseData: PolarExerciseData
    
    init(_ polarExerciseData: PolarExerciseData) {
        self.polarExerciseData = polarExerciseData
    }
    
    enum CodingKeys: String, CodingKey {
        case interval
        case samples
    }
    
    func encode(to encoder: Encoder) {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encode(polarExerciseData.interval, forKey: .interval)
        try? container.encode(polarExerciseData.samples, forKey: .samples)
    }
}

// class PolarExerciseEntryCodable TODO

class PolarGyroDataCodable: Encodable {
    let polarGyroData: PolarGyroData
    
    init(_ polarGyroData: PolarGyroData) {
        self.polarGyroData = polarGyroData
    }
    
    enum CodingKeys: String, CodingKey {
        case timeStamp
        case samples
    }
    
    func encode(to encoder: Encoder) {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encode(polarGyroData.timeStamp, forKey: .timeStamp)
        try? container.encode(polarGyroData.samples.map {
            [
                "x": $0.x,
                "y": $0.y,
                "z": $0.z
            ]
        }, forKey: .samples)
    }
}

// class PolarHrBroadcastDataCodable TODO

class PolarMagnetometerDataCodable: Encodable {
    let polarMagnetometerData: PolarMagnetometerData
    
    init(_ polarMagnetometerData: PolarMagnetometerData) {
        self.polarMagnetometerData = polarMagnetometerData
    }
    
    enum CodingKeys: String, CodingKey {
        case timeStamp
        case samples
    }
    
    func encode(to encoder: Encoder) {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encode(polarMagnetometerData.timeStamp, forKey: .timeStamp)
        try? container.encode(polarMagnetometerData.samples.map {
            [
                "x": $0.x,
                "y": $0.y,
                "z": $0.z
            ]
        }, forKey: .samples)
    }
}

class PolarOhrDataCodable: Encodable {
    let polarOhrData: PolarOhrData
    
    init(_ polarOhrData: PolarOhrData) {
        self.polarOhrData = polarOhrData
    }
    
    enum CodingKeys: String, CodingKey {
        case timeStamp
        case type
        case samples
    }
    
    func encode(to encoder: Encoder) {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encode(polarOhrData.timeStamp, forKey: .timeStamp)
        try? container.encode(polarOhrData.type.rawValue, forKey: .type)
        try? container.encode(polarOhrData.samples, forKey: .samples)
    }
}

class PolarPpiDataCodable: Encodable {
    let polarPpiData: PolarPpiData
    
    init(_ polarPpiData: PolarPpiData) {
        self.polarPpiData = polarPpiData
    }
    
    enum CodingKeys: String, CodingKey {
        case timeStamp
        case samples
    }
    
    func encode(to encoder: Encoder) {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encode(polarPpiData.timeStamp, forKey: .timeStamp)
        try? container.encode(polarPpiData.samples.map {
            [
                "hr": $0.hr,
                "ppInMs": Int($0.ppInMs),
                "errorEstimate": Int($0.ppErrorEstimate),
                "blockerBit": $0.blockerBit,
                "skinContactStatus": $0.skinContactStatus,
                "skinContactSupported": $0.skinContactSupported
            ]
        }, forKey: .samples)
    }
}

class PolarSensorSettingCodable: Codable {
    let polarSensorSetting: PolarSensorSetting
    
    init(_ polarSensorSetting: PolarSensorSetting) {
        self.polarSensorSetting = polarSensorSetting
    }
    
    required init(from decoder: Decoder) {
        let container = try? decoder.container(keyedBy: CodingKeys.self)
        
        // Flutter can only send [String: UInt32]
        let dict: [String: UInt32] = (try? container?.decode([String: UInt32].self, forKey: .settings)) ?? [:]
        let newDict = Dictionary(
            uniqueKeysWithValues:
            dict.map { key, value in
                (PolarSensorSetting.SettingType(rawValue: Int(key) ?? -1) ?? PolarSensorSetting.SettingType.unknown, value)
            }
        )
        
        polarSensorSetting = PolarSensorSetting(newDict)
    }
    
    enum CodingKeys: String, CodingKey {
        case settings
    }
    
    func encode(to encoder: Encoder) {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        let newDict = Dictionary(
            uniqueKeysWithValues:
            polarSensorSetting.settings.map { key, value in (key.rawValue, value) }
        )
        
        try? container.encode(newDict, forKey: .settings)
    }
}
