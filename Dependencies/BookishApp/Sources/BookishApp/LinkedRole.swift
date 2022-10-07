// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/10/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// A combination of a record and a role.
/// A record can be linked to another record in multiple roles. For example
/// a person could be both author and illustrator of the same book.
///
/// To show a list of all the links from a record, SwiftUI needs each list
/// item to have a unique identifier. Since the same record might crop up
/// multiple times, we can't just use the record id. Instead we need a
/// combination of the record id and the role.
///
struct LinkedRole: Identifiable {
    let role: CDRecord
    let record: CDRecord
    let link: CDRecord
    var id: String { "\(role).\(record.id)" }
}
