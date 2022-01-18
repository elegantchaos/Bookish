// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/01/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

public class InterchangeContainer {
    public typealias Index = [String:InterchangeRecord]

    public init() {
        self.index = [:]
    }
    
    public private(set) var index: Index

    public enum AddResult {
        case added
        case alreadyExists
    }
    
    public func add(_ record: InterchangeRecord) -> AddResult {
        let id = record.id.id
        guard index[id] == nil else { return .alreadyExists }
        
        index[id] = record
        print("added \(record.id)")
        return .added
    }
}
