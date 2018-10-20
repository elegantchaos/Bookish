// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 20/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

public class DetailDataSource {
    let details = DetailSpec.standardDetails
    var people = [PersonRole]()
    
    var rows: Int {
        return details.count + people.count
    }
    
    func identifier(for row: Int) -> String {
        if row < people.count {
            return "person"
        } else {
            return "detail"
        }
    }
    
    func details(for row: Int) -> DetailSpec {
        return details[row - people.count]
    }
    
    func person(for row: Int) -> PersonRole {
        return people[row]
    }
    
}
