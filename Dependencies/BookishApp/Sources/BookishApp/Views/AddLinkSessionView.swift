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
        AddLinkView(kind: session.kind, delegate: delegate)
    }
}
