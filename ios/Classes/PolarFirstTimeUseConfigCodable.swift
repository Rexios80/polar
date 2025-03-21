import Foundation
import PolarBleSdk

struct PolarFirstTimeUseConfigCodable: Codable {
    let gender: Gender
    let date: Date
    let height: Double
    let weight: Double
    let maxHeartRate: Int
    let vo2Max: Int
    let restingHeartRate: Int
    let trainingBackground: TrainingBackground
    let deviceTime: String
    let typicalDay: TypicalDay
    let sleepGoalMinutes: Int

    var data: PolarFirstTimeUseConfig {
        return PolarFirstTimeUseConfig(
            gender: gender,
            date: date,
            height: height,
            weight: weight,
            maxHeartRate: maxHeartRate,
            vo2Max: vo2Max,
            restingHeartRate: restingHeartRate,
            trainingBackground: trainingBackground,
            deviceTime: deviceTime,
            typicalDay: typicalDay,
            sleepGoalMinutes: sleepGoalMinutes
        )
    }
}

enum Gender: String, Codable {
    case male
    case female
}

enum TrainingBackground: Int, Codable {
    case occasional = 10
    case regular = 20
    case frequent = 30
    case heavy = 40
    case semiPro = 50
    case pro = 60
}

enum TypicalDay: Codable {
    case mostlySitting
    case mostlyStanding
    case mostlyMoving

    var value: Int {
        switch self {
        case .mostlySitting: return 1
        case .mostlyStanding: return 2
        case .mostlyMoving: return 3
        }
    }

    var name: String {
        switch self {
        case .mostlySitting: return "Mostly Sitting"
        case .mostlyStanding: return "Mostly Standing"
        case .mostlyMoving: return "Mostly Moving"
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(Int.self)
        switch value {
        case 1: self = .mostlySitting
        case 2: self = .mostlyStanding
        case 3: self = .mostlyMoving
        default:
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid value")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}
