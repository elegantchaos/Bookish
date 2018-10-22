// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 20/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

public class DetailDataSource {
    public let details = DetailSpec.standardDetails
    public var people = [PersonRole]()
    
    public init() {
        
    }
    
    public var rows: Int {
        return details.count + people.count
    }
    
    public func identifier(for row: Int) -> String {
        if row < people.count {
            return "person"
        } else {
            return "detail"
        }
    }
    
    public func details(for row: Int) -> DetailSpec {
        return details[row - people.count]
    }
    
    public func person(for row: Int) -> PersonRole {
        return people[row]
    }
    
}
