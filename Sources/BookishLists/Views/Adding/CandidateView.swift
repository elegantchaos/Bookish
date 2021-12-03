// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 09/03/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI
import SwiftUIExtensions

extension LookupCandidate: AutoLinked {
    public var linkView: some View {
        return CandidateDetailView(candidate: self)
    }
    
    public var labelView: some View {
        Label {
            VStack(alignment: .leading) {
                Text(title)
                Text(authors.joined(separator: ", "))
                    .font(.footnote)
            }
        } icon: {
            if let url = image {
                LabelIconView(url: url, placeholder: "book")
            } else {
                Image(systemName: "book")
            }
        }
    }
}
