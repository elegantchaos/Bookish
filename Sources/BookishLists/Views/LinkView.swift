// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 12/01/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI
import SwiftUIExtensions
//
//extension BookList: ListItemLinkable {
//    static func linkView(binding: Binding<BookList>) -> some View {
//        BookListView(list: binding)
//    }
//}

extension BookList: ListItemViewable {
    static func iconView(binding: Binding<BookList>) -> Image? {
        Image(systemName: "books.vertical")
    }
    
    static func labelView(binding: Binding<BookList>) -> some View {
        Text(binding.wrappedValue.name)
    }
}
//
//extension Book: ListItemLinkable {
//    static func linkView(binding: Binding<Book>) -> some View {
//        BookView(book: binding)
//    }
//}

extension Book: ListItemViewable {
    static func iconView(binding: Binding<Book>) -> Image? {
        Image(systemName: "book")
    }
    
    static func labelView(binding: Binding<Book>) -> some View {
        Text(binding.wrappedValue.name)
    }
}
