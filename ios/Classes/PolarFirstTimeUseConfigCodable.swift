import Foundation
import PolarBleSdk

enum Gender: String, Decodable {
    case male
    case female
}

enum TrainingBackground: Int, Decodable {
    case occasional = 10
    case regular = 20
    case frequent = 30
    case heavy = 40
    case semiPro = 50
    case pro = 60
}

enum TypicalDay: Decodable {
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
}

extension PolarFirstTimeUseConfig: Decodable {
    enum CodingKeys: String, CodingKey {
        case gender
        case birthDate
        case height
        case weight
        case maxHeartRate
        case vo2Max
        case restingHeartRate
        case trainingBackground
        case deviceTime
        case typicalDay
        case sleepGoalMinutes
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)// Decode and map String to Gender enum
        let genderString = try container.decode(String.self, forKey: .gender)
        guard let gender = Gender(rawValue: genderString) else {
            throw DecodingError.dataCorruptedError(forKey: .gender, in: container, debugDescription: "Invalid gender value")
        }

        let birthDate = try container.decode(Date.self, forKey: .birthDate)
        let height = try container.decode(Float.self, forKey: .height)
        let weight = try container.decode(Float.self, forKey: .weight)
        let maxHeartRate = try container.decode(Int.self, forKey: .maxHeartRate)
        let vo2Max = try container.decode(Int.self, forKey: .vo2Max)
        let restingHeartRate = try container.decode(Int.self, forKey: .restingHeartRate)

        let trainingBackgroundValue = try container.decode(Int.self, forKey: .trainingBackground)
        guard let trainingBackground = TrainingBackground(rawValue: trainingBackgroundValue) else {
            throw DecodingError.dataCorruptedError(forKey: .trainingBackground, in: container, debugDescription: "Invalid training background")
        }
        let deviceTime = try container.decode(String.self, forKey: .deviceTime)
        let typicalDay = try container.decode(TypicalDay.self, forKey: .typicalDay)
        let sleepGoalMinutes = try container.decode(Int.self, forKey: .sleepGoalMinutes)
        
        self.init(
            gender: gender,
               birthDate: birthDate,
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
