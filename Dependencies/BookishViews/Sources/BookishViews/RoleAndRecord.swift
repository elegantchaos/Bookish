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
struct RoleAndRecord: Identifiable {
    let role: CDRecord
    let record: CDRecord
    let link: CDRecord
    var id: String { "\(role).\(record.id)" }
}

extension CDRecord {
    var asLink: RoleAndRecord? {
        guard let role = containersWithKind(.role).first, let target = containersExcludingKind(.role).first else { return nil }
        return RoleAndRecord(role: role, record: target, link: self)
    }

    /// Return a list of the role/record pairs associated with this record.
    func linkedRecords() -> [RoleAndRecord] {
        let linkRecords = linksTo()
        return linkRecords.compactMap { $0.asLink }
    }

}
