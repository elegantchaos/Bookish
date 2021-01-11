// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/01/2021.
//  All code (c) 2021 - present day, Sam Deane.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var model: Model

    @State var selection: UUID? = nil
    
    var body: some View {
        NavigationView {
            VStack {
                List(selection: $selection) {
                    ForEach(model.lists.order, id: \.self) { id in
                        let list = model.binding(forBook: id)
                        NavigationLink(destination: BookListView(list: list)) {
                            Text(list.wrappedValue.name)
                        }
                    }
                }
            }
            .navigationTitle(model.appName)
            .navigationBarItems(
                leading: EditButton(),
                trailing:
                    HStack {
                        Button(action: handleAdd) { Image(systemName: "plus") }
                    }
            )
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func handleAdd() {
        let list = BookList(id: UUID(), name: "Untitled", entries: [], values: [:])
        model.lists.order.append(list.id)
        model.lists.values[list.id] = list
    }
}
