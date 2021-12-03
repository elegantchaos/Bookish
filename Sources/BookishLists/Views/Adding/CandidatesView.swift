// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 03/12/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUIExtensions
import SwiftUI

struct CandidatesView: View {
    let candidates: [LookupCandidate]
    @Binding var selection: UUID?
    
    var body: some View {
        List {
            ForEach(candidates) { candidate in
                LinkView(candidate, selection: $selection)
            }
        }
        .listStyle(.plain)
    }
}

