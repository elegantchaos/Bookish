// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 09/03/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

struct CandidateView: View {
    let candidate: LookupCandidate
    
    var body: some View {
        HStack {
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
