// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 16/09/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import ThreadExtensions

extension CDRecord {
    /// The identifier to use for a role list for a given role
    func roleID(_ role: CDRecord) -> String {
        return "\(role.id).\(id)"
    }

    /// Add another record in a given role to this record
    @discardableResult func addLink(to record: CDRecord, role: CDRecord? = nil) -> CDRecord {
        // make a link record
        let link = CDRecord.make(kind: .link, in: managedObjectContext!)
        link.addToContents(self)    // the link points to this item...
        link.addToContents(record)  // ... and to the other record
        role?.addToContents(link)  // if a role was passed, that points to the link
        return link
    }

    /// Return all links pointing at this record.
    func linksTo() -> [CDRecord] {
        let linkRecords = containersWithKind(.link)
        return linkRecords
    }

    /// Assume that this is a role, and return all the links
    /// using it.
    func linksForRole() -> [CDRecord] {
        assert(kind == .role)
        let linkRecords = contentsWithKind(.link)
        return linkRecords
    }

    /// Assume that this is a link, and return all the things it is connecting.
    /// We can optionally exclude a record - typically this will be a record
    /// that is looking for other links to itself.
    func linkConnections(excluding: CDRecord? = nil) -> Set<CDRecord> {
        assert(kind == .link)
        guard var contents else { return [] }
        if let excluding {
            contents.remove(excluding)
        }

        return contents
    }

    /// Assuming that this is a link, and that it's linking
    /// to a given record, return the other record it links to,
    /// and the role that it is linked as.
    func asLinkedRole(to record: CDRecord) -> LinkedRole? {
        assert(kind == .link)
        assert(contents!.contains(record))
        
        guard let role = containersWithKind(.role).first else { return nil }
        guard let target = contents?.first(where: { $0 != record }) else { return nil }
        return LinkedRole(role: role, record: target, link: self)
    }

    /// Return a list of the role/record pairs associated with this record.
    func linkedRoles() -> [LinkedRole] {
        let linkRecords = linksTo()
        return linkRecords.compactMap { $0.asLinkedRole(to: self) }
    }

    /// Return the names of all the roles that a given record fulfils
    /// for this record.
    func roles(for record: CDRecord) -> [CDRecord] {
        let roleRecords = linksTo()                                 // lists of links to this record
            .compactMap { $0.containedBy }                          // filter anything without content
            .filter { $0.contains(record) }                         // keep the ones containing the record we're interested in
            .compactMap { $0.first { $0.kind == .role } }           // extract the linked roles
        
        return roleRecords
    }
}
