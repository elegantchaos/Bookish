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
    
    public init(_ content: [Any]) throws {
        let records = try content.map { try InterchangeRecord($0) }
        var index: Index = [:]
        for record in records {
            index[record.id.id] = record
        }
        self.index = index
    }
    
    public private(set) var index: Index

    public enum AddResult {
        case added
        case alreadyExists
    }
    
    @discardableResult public func add(_ record: InterchangeRecord) -> AddResult {
        let id = record.id.id
        guard index[id] == nil else { return .alreadyExists }
        
        index[id] = record
        print("added \(record.id)")
        return .added
    }
    
    public func asList() throws -> [Any] {
        return index.values.sorted(by: { $0.id.id < $1.id.id }).map({ $0.asDictionary })
    }
}
