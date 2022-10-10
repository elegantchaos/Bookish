// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/10/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreData
import Foundation
import Logger
import NavigationPathExtensions
import SwiftUI
import ThreadExtensions

let navigationChannel = Channel("Navigation")

public class NavigationController: ObservableObject {
    lazy var defaultFields = makeDefaultFields()
    
    var path: NavigationPath
    
    public init(context: NSManagedObjectContext) {
        self.path = .loadFromDefaults(context: context)
    }
    
    public func save() {
        path.saveToDefaults()
    }
    
    func fields(for link: RecordWithContext) -> FieldList {
        link.context?.fields ?? defaultFields
    }
    
    func destinationByID(_ id: String) -> some View {
        print("destination \(id)")
        return Group {
            if id == .rootPreferencesID {
                PreferencesView()
            } else {
                EmptyView()
            }
        }
    }
    
    func destinationByRecord(_ link: RecordWithContext) -> some View {
        print("destination \(link)")

        return VStack {
            let record = link.record

            if record.isBook {
                BookView(book: record, fields: fields(for: link))
            } else {
                switch record.kind {
                    case .list:
                        CustomListView(list: record, fields: defaultFields)
                        
                    case .role:
                        RoleView(role: record, excludingKind: .book)
                        
                    case .organisation, .series, .person:
                        BackLinksIndexView(list: record)
                        
                    default:
                        ListIndexView(list: record)
                }
            }
        }
    }
    
    func destinationByKind(_ kind: RecordKind) -> some View {
        print("destination \(kind)")
        return KindIndexView(kind: kind)
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

extension String {
    static let defaultPathKey = "path"
}

extension NavigationPath {
    func saveToDefaults(key: String = .defaultPathKey) {
        do {
            try UserDefaults.standard.set(self, forKey: .defaultPathKey)
        } catch {
            navigationChannel.log("Couldn't encode path")
        }
    }
    
    static func loadFromDefaults(context: NSManagedObjectContext) -> NavigationPath {
        do {
            let decoder = JSONDecoder()
            decoder.userInfo[.coreDataContextKey] = context
            if let path = try UserDefaults.standard.path(forKey: .defaultPathKey, decoder: decoder) {
                navigationChannel.log("Restored path \(path)")
                return path
            }
        } catch {
            navigationChannel.log("Couldn't decode path \(error)")
        }
        
        return NavigationPath()
    }
}
