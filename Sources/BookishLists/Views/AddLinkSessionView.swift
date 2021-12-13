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
        switch session.kind {
            case .person:
                AddLinkView(PersonFetchProvider.self, delegate: delegate)

            case .series:
                AddLinkView(SeriesFetchProvider.self, delegate: delegate)
                
            case .publisher:
                AddLinkView(PublisherFetchProvider.self, delegate: delegate)
                
            default:
                EmptyView()
        }
    }
}
