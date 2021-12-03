// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 03/12/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

struct CandidateDetailView: View {
    @EnvironmentObject var appearance: AppearanceController
    
    let candidate: LookupCandidate
    
    var body: some View {
        VStack {
            HStack {
                Label("title", systemImage: "tag")
                Text(candidate.title)
            }

            HStack {
                Label("authors", systemImage: "person.2")
                Text(candidate.authors.joined(separator: ", "))
            }

            HStack {
                Label("publisher", systemImage: "tag")
                Text(candidate.publisher)
            }

            if let date = candidate.date {
                HStack {
                    Label("date", systemImage: "calendar")
                    Text(appearance.formatted(date: date))
                }
            }

            HStack {
                Label("service", systemImage: "tag")
                Text(candidate.service.name)
            }

        }
    }
}
