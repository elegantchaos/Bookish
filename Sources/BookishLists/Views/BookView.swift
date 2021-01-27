// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 12/01/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

import SwiftUI

struct BookView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @EnvironmentObject var model: Model
    @State var selection: UUID? = nil
    @ObservedObject var book: CDBook

    var body: some View {
        VStack {
            TextField("Name", text: $book.name)
                .padding()

            TextField("Notes", text: book.binding(forProperty: "notes"))
                .padding()
            
            ScrollView {
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
        .navigationTitle(book.name)
        .onDisappear(perform: handleDisappear)
    }
    
    func handleDisappear() {
        model.save()
    }
}
