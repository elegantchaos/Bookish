// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 12/01/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

import SwiftUI

struct BookView: View {
    @EnvironmentObject var model: Model
    @State var selection: UUID? = nil
    @Binding var book: Book

    var body: some View {
        VStack {
            TextField("Name", text: $book.name)
                .padding()
            
        }
        .navigationTitle(book.name)
    }
}
