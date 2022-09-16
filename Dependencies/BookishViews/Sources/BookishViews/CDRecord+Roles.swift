// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 16/09/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

extension CDRecord {
    func addRole(_ role: String, for record: CDRecord) {
        // find the list for the given role
        let roleID = "\(role).\(id)"
        let roleRecord = findOrMakeChildWithID(roleID, kind: .role) { created in
            created.name = role
        }

        // add the record to the list
        roleRecord.addToContents(record)
    }

    func removeRole(_ role: String, of record: CDRecord) {
        // find the list for the given role
        let roleID = "\(role).\(record.id)"
        if let roleRecord = findChildWithID(roleID, kind: .role) {
            // remove record from the list
            roleRecord.removeFromContents(self)
            
            // if it's empty, remove the list too
            if roleRecord.contents?.count == 0 {
                removeFromContents(roleRecord)
            }
        }
    }

    struct RoleEntry: Identifiable {
        let record: CDRecord
        let role: String
        var id: String {
            "\(role).\(record.id)"
        }
    }
    
    func roleEntries() -> [RoleEntry] {
        var entries: [RoleEntry] = []
        for role in roleRecords() {
            let roleName = role.name
            if let recordsInRole = role.contents {
                for record in recordsInRole {
                    entries.append(.init(record: record, role: roleName))
                }
            }
        }
        
        return entries
    }
    
    func roleRecords() -> [CDRecord] {
        let roleRecords = childredWithKind(.role)
        return roleRecords
    }

    func roles(for record: CDRecord) -> [String] {
        let roleRecords = roleRecords().filter({ $0.contents?.contains(record) ?? false })
        let roles = roleRecords.map { $0.name }
        return roles
    }

    func sortedRoles(for record: CDRecord) -> [String] {
        let roleRecords = childredWithKind(.role)
        let roles = roleRecords.map { $0.name }
        return roles.sorted()
    }

    var defaultRole: String {
        return kind.defaultRole
    }
}
