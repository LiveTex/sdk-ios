//
//  Rate.swift
//
//
//  Created by Yuri on 18.09.2024.
//

public struct Rate: Decodable {
    public let enabledType: TypeVote?
    public let isSet: VoteResult?
}

public struct VoteResult: Codable {
    public let type: TypeVote
    public let value: String
    
    public init(type: TypeVote, value: String) {
            self.type = type
            self.value = value
        }
}

public enum TypeVote: String, Codable {
    case doublePoint
    case fivePoint
  
    func stringValue() -> String {
        switch self{
        case .doublePoint:
            return "doublePoint"
        case .fivePoint:
            return "fivePoint"
        }
    }
}
