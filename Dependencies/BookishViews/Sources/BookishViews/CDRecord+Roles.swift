// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 16/09/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

extension CDRecord {
    
    /// A combination of a record and a role.
    /// A record can be linked to another record in multiple roles. For example
    /// a person could be both author and illustrator of the same book.
    ///
    /// To show a list of all the links from a record, SwiftUI needs each list
    /// item to have a unique identifier. Since the same record might crop up
    /// multiple times, we can't just use the record id. Instead we need a
    /// combination of the record id and the role.
    struct RoleAndRecord: Identifiable {
        let role: String
        let record: CDRecord
        var id: String { "\(role).\(record.id)" }
    }
    

    /// The identifier to use for a role list for a given role
    func roleID(_ role: String) -> String {
        return "\(role).\(id)"
    }

    /// Add another record in a given role to this record
    func addRole(_ role: String, for record: CDRecord) {
        // find the list for the given role
        let roleID = roleID(role)
        let roleRecord = findOrMakeChildWithID(roleID, kind: .roleList) { created in
            created.name = role
        }

        // add the record to the list
        roleRecord.addToContents(record)
    }

    /// Remove a given role for another record from this record.
    func removeRole(_ role: String, of record: CDRecord) {
        // find the list for the given role
        let roleID = roleID(role)
        if let roleRecord = findChildWithID(roleID, kind: .roleList) {
            // remove record from the list
            roleRecord.removeFromContents(record)
            
            // if it's empty, remove the list too
            if roleRecord.contents?.count == 0 {
                removeFromContents(roleRecord)
            }
        }
    }

    /// Return all the role lists for this record.
    func roleLists() -> [CDRecord] {
        let roleRecords = childredWithKind(.roleList)
        return roleRecords
    }

    /// Return the names of all the roles that a given record fulfils
    /// for this record.
    func roleNames(for record: CDRecord) -> [String] {
        let roleRecords = roleLists().filter({ $0.contents?.contains(record) ?? false })
        let roles = roleRecords.map { $0.name }
        return roles
    }

    /// Return a list of the role/record pairs associated with this record.
    func roles() -> [RoleAndRecord] {
        var entries: [RoleAndRecord] = []
        for role in roleLists() {
            let roleName = role.name
            if let recordsInRole = role.contents {
                for record in recordsInRole {
                    entries.append(.init(role: roleName, record: record))
                }
            }
        }
        
        return entries
    }
    

}
