// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 12/01/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

protocol Labelled {
    static func labelView(binding: Binding<Self>) -> LabelType
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
    static func labelView(binding: Binding<BookList>) -> some View {
        Text(binding.wrappedValue.name)
    }
}

extension Book: Linkable {
    static func linkView(binding: Binding<Book>) -> some View {
        BookView(book: binding)
    }
}

extension Book: Labelled {
    static func labelView(binding: Binding<Book>) -> some View {
        Text(binding.wrappedValue.name)
    }
}
