// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 12/01/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

protocol Labelled {
    static func labelView(binding: Binding<Self>) -> LabelType
    static func iconView(binding: Binding<Self>) -> Image?
    associatedtype LabelType: View
}

protocol Linkable {
    static func linkView(binding: Binding<Self>) -> LinkType
    associatedtype LinkType: View
}

struct LinkView<T>: View where T: Linkable, T: Labelled {
    let binding: Binding<T>
    
    var body: some View {
        NavigationLink(destination: T.linkView(binding: binding)) {
            LabelView(binding: binding)
        }
    }
}

struct LabelView<T>: View where T: Labelled {
    let binding: Binding<T>
    
    var body: some View {
        HStack {
            if let icon = T.iconView(binding: binding) {
                icon
            }
            T.labelView(binding: binding)
        }
    }
}

extension BookList: Linkable {
    static func linkView(binding: Binding<BookList>) -> some View {
        BookListView(list: binding)
    }
}

extension BookList: Labelled {
    static func iconView(binding: Binding<BookList>) -> Image? {
        Image(systemName: "books.vertical")
    }
    
    static func labelView(binding: Binding<BookList>) -> some View {
        Text(binding.wrappedValue.name)
    }
}

extension Book: Linkable {
    static func iconView(binding: Binding<Book>) -> Image? {
        Image(systemName: "book")
    }
    
    static func linkView(binding: Binding<Book>) -> some View {
        BookView(book: binding)
    }
}

extension Book: Labelled {
    static func labelView(binding: Binding<Book>) -> some View {
        Text(binding.wrappedValue.name)
    }
}
