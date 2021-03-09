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
            Text(title)
        } icon: {
            if let string = image, let url = URL(string: string) {
                LabelIconView(url: url, placeholder: "book")
            } else {
                Image(systemName: "book")
            }
        }
    }
}

struct CandidateView: View {
    let candidate: LookupCandidate
    
    var body: some View {
        HStack {
            LinkView(candidate, selection: .constant(nil))
            Text(candidate.title)
            Text(candidate.authors.joined(separator: ", "))
            Button(action: handleAdd) {
                Image(systemName: "plus.circle")
            }
        }
    }
    
    func handleAdd() {
        
    }
}

struct CandidateDetailView: View {
    let candidate: LookupCandidate

    var body: some View {
        Text("detail here")
    }
}
