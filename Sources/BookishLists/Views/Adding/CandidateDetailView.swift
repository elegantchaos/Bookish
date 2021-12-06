// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 03/12/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

struct CandidateDetailView: View {
    @EnvironmentObject var appearance: AppearanceController
    @EnvironmentObject var model: Model
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var candidate: LookupCandidate
    
    var body: some View {
        VStack(alignment: .leading) {
            PropertyView(label: "title", icon: "tag", value: candidate.title)
            PropertyView(label: "authors", icon: "person.2", value: candidate.authors.joined(separator: ", "))
            PropertyView(label: "publisher", icon: "building.2", value: candidate.publisher)

            if let date = candidate.book.properties[asDate: .publishedDateKey] {
                PropertyView(label: "date", icon: "calendar", value: appearance.formatted(date: date))
            }

            PropertyView(label: "found by", icon: "globe", value: candidate.service.name)
            
            let image = model.images.image(for: candidate.image)
            AsyncImageView(image)
                .frame(maxWidth: 256, maxHeight: 256)
        
            Spacer()

            HStack {
                Spacer()
                Menu {
                    Button("A", action: handleAdd)
                    Button("B", action: handleAdd)
                    Button("C", action: handleAdd)
                } label: {
                    Text("Add To Collection")
                } primaryAction: {
                    handleAdd()
 
                }
                .foregroundColor(.white)
                .padding(4.0)
                .background(
                    RoundedRectangle(cornerRadius: 8.0, style: .continuous)
                        .foregroundColor(.accentColor)
                )
            }
        }
        .padding()
    }
    
    func handleAdd() {
        model.importFrom([candidate.book])
        candidate.imported = true
        presentationMode.wrappedValue.dismiss()
    }
}

struct MainActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 4.0, style: .continuous)
                    .foregroundColor(.red)
            )
    }
}
