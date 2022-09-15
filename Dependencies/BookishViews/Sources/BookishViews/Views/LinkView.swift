// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 12/01/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI
import SwiftUIExtensions


protocol Labelled where LabelView: View {
    associatedtype LabelView
    var labelView: LabelView { get }
}

struct LabelView<Item>: View where Item: Labelled {
    let item: Item
    
    init(_ item: Item) {
        self.item = item
    }
    
    var body: some View {
        item.labelView
    }
}

protocol Linkable: Labelled, Identifiable where ItemView: View {
    associatedtype ItemView
    var linkView: ItemView { get }
}

struct LinkView<Item>: View where Item: Linkable {
    let item: Item
    
    init(_ item: Item) {
        self.item = item
    }
    
    var body: some View {
        NavigationLink(destination: item.linkView) {
            LabelView(item)
        }
        .tag(item.id)

    }
}
//
//extension BookList: ListItemLinkable {
//    static func linkView(binding: Binding<BookList>) -> some View {
//        BookListView(list: binding)
//    }
//}
//
//extension BookList: ListItemViewable {
//    static func iconView(binding: Binding<BookList>) -> Image? {
//        Image(systemName: "books.vertical")
//    }
//
//    static func labelView(binding: Binding<BookList>) -> some View {
//        Text(binding.wrappedValue.name)
//    }
//}
//
//extension Book: ListItemLinkable {
//    static func linkView(binding: Binding<Book>) -> some View {
//        BookView(book: binding)
//    }
//}
//
//extension Book: ListItemViewable {
//    static func iconView(binding: Binding<Book>) -> Image? {
//        Image(systemName: "book")
//    }
//
//    static func labelView(binding: Binding<Book>) -> some View {
//        Text(binding.wrappedValue.name)
//    }
//}
