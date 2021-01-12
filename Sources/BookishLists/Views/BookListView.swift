// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/01/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

struct BookListView: View {
    @EnvironmentObject var model: Model
    @State var selection: UUID? = nil
    @Binding var list: BookList

    var body: some View {
        VStack {
            TextField("Name", text: $list.name)
                .padding()
            
            List(selection: $selection) {
                ForEach(list.entries, id: \.self) { id in
                    let book = model.binding(forBook: id)
                    NavigationLink(destination: BookView(book: book)) {
                        Text(book.wrappedValue.name)
                    }
                }
            }
        }
        .navigationTitle(list.name)
        .navigationBarItems(
            leading: EditButton(),
            trailing:
                HStack {
                    Button(action: handleAdd) { Image(systemName: "plus") }
                }
        )
    }
    
    func handleAdd() {
        let book = Book(id: UUID().uuidString, name: "Untitled Book")
        list.entries.append(book.id)
        model.books.append(book)
    }
}
