// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 03/12/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

struct CandidateDetailView: View {
    @EnvironmentObject var appearance: AppearanceController
    @EnvironmentObject var model: Model
    
    let candidate: LookupCandidate
    
    var body: some View {
        VStack(alignment: .leading) {
            PropertyView(label: "title", icon: "tag", value: candidate.title)
            PropertyView(label: "authors", icon: "person.2", value: candidate.authors.joined(separator: ", "))
            PropertyView(label: "publisher", icon: "building.2", value: candidate.publisher)

            if let date = candidate.date {
                PropertyView(label: "date", icon: "calendar", value: appearance.formatted(date: date))
            }

            PropertyView(label: "found by", icon: "globe", value: candidate.service.name)
            
            Spacer()
            
            Button(action: handleAdd) {
                Text("Add To Collection")
            }
        }
    }
    
    func handleAdd() {
        model.importFromDictionaries(dictionaries: [candidate.importProperties])
    }
}
