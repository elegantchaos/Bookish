// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/10/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import SwiftUI


public class NavigationController: ObservableObject {
    lazy var defaultFields = makeDefaultFields()
    
    @Published var path: NavigationPath {
        didSet {
            print(path)
        }
    }
    
    public init() {
        self.path = .init()
    }
    
    func fields(for link: RecordWithContext) -> FieldList {
        link.context?.fields ?? defaultFields
    }
    
    func destinationByID(_ id: String) -> some View {
        Group {
            if id == .rootPreferencesID {
                PreferencesView()
            } else {
                EmptyView()
            }
        }
    }
    
    func destinationByRecord(_ link: RecordWithContext) -> some View {
        let record = link.record
        return VStack {
            if record.isBook {
                BookView(book: record, fields: fields(for: link))
            } else {
                switch record.kind {
                    case .list:
                        CustomListView(list: record, fields: defaultFields)
                        
                    case .role:
                        LinksIndexView(list: record)
                        
                    case .publisher, .series, .person:
                        BackLinksIndexView(list: record)
                        
                    default:
                        ListIndexView(list: record)
                }
            }
        }
    }
    
    func destinationByKind(_ kind: RecordKind) -> some View {
        KindIndexView(kind: kind)
    }
    
    func makeDefaultFields() -> FieldList {
        let list = FieldList()
        list.addField(Field(.description, kind: .paragraph, layout: .belowNoLabel))
        list.addField(Field(.notes, kind: .paragraph, layout: .below))
        list.addField(Field(.addedDate, kind: .date, label: "added"))
        list.addField(Field(.publishedDate, kind: .date, label: "published"))
        list.addField(Field(.format, kind: .string))
        list.addField(Field(.asin, kind: .string, icon: "barcode"))
        list.addField(Field(.isbn, kind: .string, icon: "barcode"))
        list.addField(Field(.dewey, kind: .string))
        list.addField(Field(.pages, kind: .number))
        return list
    }
}

struct NavigationModifier: ViewModifier {
    @EnvironmentObject var navigation: NavigationController
    
    func body(content: Content) -> some View {
        content
            .navigationDestination(for: String.self, destination: navigation.destinationByID)
            .navigationDestination(for: RecordKind.self, destination: navigation.destinationByKind)
            .navigationDestination(for: RecordWithContext.self, destination: navigation.destinationByRecord)
    }
}

extension View {
    func standardNavigation() -> some View {
        self.modifier(NavigationModifier())
    }
}
