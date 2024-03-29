// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 03/12/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

struct CandidateDetailView: View {
    @EnvironmentObject var appearance: AppearanceController
    @EnvironmentObject var importController: ImportController
    @EnvironmentObject var model: ModelController
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var candidate: LookupCandidate
    
    var body: some View {
        VStack(alignment: .leading) {
            PropertyView(label: "title", icon: "tag", value: candidate.title, layout: .inline)
            PropertyView(label: "authors", icon: "person.2", value: candidate.authors.joined(separator: ", "), layout: .inline)
            PropertyView(label: "publisher", icon: "building.2", value: candidate.publisher, layout: .inline)

            if let date = candidate.book.date(forKey: .publishedDate) {
                PropertyView(label: "date", icon: "calendar", value: appearance.formatted(date: date), layout: .inline)
            }

            PropertyView(label: "found by", icon: "globe", value: candidate.service.name, layout: .inline)
            
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
        importController.import(from: [candidate.book])
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
