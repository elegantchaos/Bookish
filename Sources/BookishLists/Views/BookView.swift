// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 12/01/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

import SwiftUI

struct BookView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @EnvironmentObject var model: Model
    @ObservedObject var book: CDBook

    var body: some View {
        ScrollView {
        VStack {
            HStack {
                VStack {
                    TextField("Name", text: $book.name)
                        .padding()

                    TextField("Notes", text: book.binding(forProperty: "notes"))
                        .padding()
                    
                    Spacer()
                }

                Spacer()
                
                AsyncImageView(model.image(for: book))
                    .frame(maxWidth: 256, maxHeight: 256)
            }

            DisclosureGroup("Properties") {
                VStack {
                    let props = book.decodedProperties
                    ForEach(Array(props.keys.sorted()), id: \.self) { key in
                        HStack {
                            if let value = props[key] {
                                let string = String(describing: value)
                                if !string.isEmpty {
                                    Text(key)
                                    Spacer()
                                    Text(string)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
        }
        .navigationTitle(book.name)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear(perform: handleDisappear)
    }
    
    func handleDisappear() {
        model.save()
    }
}
