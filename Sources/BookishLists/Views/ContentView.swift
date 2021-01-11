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
                    ForEach(model.lists) { list in
                        Text(list.name)
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
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func handleAdd() {
        model.lists.append(BookList(id: UUID(), name: "Untitled", entries: [:]))
    }
}
