// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 27/02/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

public class LookupService: Equatable, Hashable {
    public static func == (lhs: LookupService, rhs: LookupService) -> Bool {
        return lhs.name == rhs.name
    }
    
    public let name: String
    
    public func hash(into hasher: inout Hasher) {
        name.hash(into: &hasher)
    }
    
    public init(name: String) {
        self.name = name
    }
    
    public func lookup(search: String, session: LookupSession) {
        session.done(service: self)
    }
    
    public func cancel() {
        
    }
    
    public func restore(persisted: String) -> LookupCandidate? {
        return nil
    }
}
