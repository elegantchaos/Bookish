// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 13/12/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

struct AddLinkSessionView: View {
    struct Session {
        let kind: CDRecord.Kind
        let role: String?
    }
    
    let session: Session
    let delegate: AddLinkDelegate
    var body: some View {
        let role = session.role ?? session.kind.defaultRole
        switch session.kind {
            case .book:
                AddLinkView(BookFetchProvider.self, role: role, delegate: delegate)

            case .person:
                AddLinkView(PersonFetchProvider.self, role: role, delegate: delegate)

            case .series:
                AddLinkView(SeriesFetchProvider.self, role: role, delegate: delegate)
                
            case .publisher:
                AddLinkView(PublisherFetchProvider.self, role: role, delegate: delegate)
                
            default:
                Text(String("Missing FetchProvider for \(session.kind)"))
        }
    }
}
