// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 03/12/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUIExtensions
import SwiftUI


extension LookupCandidate: AutoLinked {
    public var linkView: CandidateDetailView {
        return CandidateDetailView(candidate: self)
    }
    
    public var labelView: CandidateLabelView {
        return CandidateLabelView(candidate: self)
    }
}

struct CandidatesView: View {
    let candidates: [LookupCandidate]
    @Binding var selection: LookupCandidate.ID?
    
    var body: some View {
        List {
            ForEach(candidates) { candidate in
                LinkView<LookupCandidate>(candidate, selection: $selection)
            }
        }
        .listStyle(.plain)
    }
}

