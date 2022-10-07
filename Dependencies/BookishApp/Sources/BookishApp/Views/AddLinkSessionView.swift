// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 13/12/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

struct AddLinkSessionView: View {
    struct Session {
        let kind: RecordKind
        let role: CDRecord?
    }
    
    let session: Session
    let delegate: AddLinkDelegate
    var body: some View {
        let role = session.role
        switch session.kind {
            case .book:
                AddLinkView(kind: session.kind, delegate: delegate)

            case .person:
                AddLinkView(kind: session.kind, delegate: delegate)

            case .series:
                AddLinkView(kind: session.kind, delegate: delegate)
                
            case .organisation:
                AddLinkView(kind: session.kind, delegate: delegate)
                
            default:
                Text(String("Missing FetchProvider for \(session.kind)"))
        }
    }
}
