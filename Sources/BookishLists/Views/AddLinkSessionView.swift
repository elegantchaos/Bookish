// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 13/12/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

struct AddLinkSessionView: View {
    let kind: CDRecord.Kind
    let delegate: AddLinkDelegate
    var body: some View {
        switch kind {
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
