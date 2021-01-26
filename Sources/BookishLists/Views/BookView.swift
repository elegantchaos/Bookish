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
            TextField("Name", text: $book.name.onNone(""))
                .padding()

            TextField("Notes", text: book.binding(forProperty: "notes"))
                .padding()
            

        }
        .navigationTitle(book.name ?? "")
        .onDisappear(perform: handleDisappear)
    }
    
    func handleDisappear() {
        model.save()
    }
}
