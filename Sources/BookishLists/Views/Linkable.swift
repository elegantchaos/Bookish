//
//  Linkable.swift
//  BookishLists
//
//  Created by Sam Developer on 12/01/2021.
//

import SwiftUI

protocol Linkable {
    func makeView() -> LinkType
    associatedtype LinkType: View
}

struct LinkView<T>: View where T: Linkable {
    let binding: T
    
    var body: some View {
        binding.makeView()
    }
}

extension Binding: Linkable where Value == BookList {
    func makeView() -> some View {
        NavigationLink(destination: BookListView(list: self)) {
            Text(self.wrappedValue.name)
        }
    }
}
//
//extension Binding: Linkable where Value == Book {
//    func makeView() -> some View {
//        NavigationLink(destination: BookView(book: self)) {
//            Text(self.wrappedValue.name)
//        }
//    }
//}
