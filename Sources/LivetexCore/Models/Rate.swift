//
//  Rate.swift
//
//
//  Created by Yuri on 18.09.2024.
//

public struct Rate: Codable {
    public let enabledType: TypeVote?
    public let commentEnabled: Bool
    public let textBefore: String?
    public let textAfter: String?
    public let isSet: VoteResult?
    
    public init( enabledType: TypeVote?, commentEnabled: Bool, textBefore: String?, textAfter: String?, isSet: VoteResult?) {
        self.enabledType = enabledType
        self.commentEnabled = commentEnabled
        self.textBefore = textBefore
        self.textAfter = textAfter
        self.isSet = isSet
    }
    
}

public struct VoteResult: Codable {
    public let type: TypeVote
    public let value: String
    public let comment: String?
    
    public init(type: TypeVote, value: String, comment: String?) {
        self.type = type
        self.value = value
        self.comment = comment
    }
}

public struct SendVoteResult: Encodable {
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
