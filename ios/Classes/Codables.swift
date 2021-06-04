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
