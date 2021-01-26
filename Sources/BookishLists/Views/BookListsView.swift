// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 20/01/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI
import SwiftUIExtensions

struct BookListsView: View {
    @EnvironmentObject var model: Model
    @FetchRequest(
        entity: CDList.entity(),
        sortDescriptors: []
    ) var lists: FetchedResults<CDList>
    
    var body: some View {
        List(lists) { list in
            NavigationLink(destination: BookListView(list: list)) {
                Text(list.name ?? "<>")
            }
        }
    }
}
