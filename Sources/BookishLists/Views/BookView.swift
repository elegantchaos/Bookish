// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 12/01/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

import SwiftUI

struct BookView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @EnvironmentObject var model: Model
    @ObservedObject var book: CDRecord
    @ObservedObject var fields: FieldList
    @State var selection: String?
    
    @AppStorage("showLinks") var showLinks = true
    @AppStorage("showRaw") var  showRaw = false
    
    var body: some View {
        ScrollView {
            VStack {
                HStack {
                    VStack {
                        //                    Label {
                        //                        TextField("Name", text: $book.name)
                        //                            .padding()
                        //                    } icon: {
                        //                        Image(systemName: "tag")
                        //                    }
                        
                        Label {
                            TextField("Notes", text: book.binding(forProperty: "notes"))
                                .padding()
                                .fixedSize(horizontal: true, vertical: false)
                        } icon: {
                            Image(systemName: "note.text")
                        }
                        
                        Spacer()
                    }
                    
                    Spacer()
                    
                    AsyncImageView(model.image(for: book, usePlacholder: false))
                        .frame(maxWidth: 256, maxHeight: 256)
                }
                .padding()
                
                ForEach(fields.fields) { field in
                    if let value = book.property(forKey: field.key) {
                        let string = String(describing: value)
                        if !string.isEmpty {
                            HStack {
                                Text(field.key)
                                Text(string)
                                Spacer()
                            }
                        }
                    }
                }
                
                DisclosureGroup("Links", isExpanded: $showLinks) {
                    VStack(alignment: .leading) {
                        if let contained = book.containedBy?.sortedByName {
                            ForEach(contained) { item in
                                HStack {
                                    RecordLink(item, nameMode: .includeRole, selection: $selection)
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                            }
                        }
                    }
                }
                
                DisclosureGroup("Raw Properties", isExpanded: $showRaw) {
                    LazyVStack(alignment: .leading) {
                        let keys = book.sortedKeys
                        ForEach(keys, id: \.self) { key in
                            if let value = book.property(forKey: key) {
                                RawPropertyView(key: key, value: value)
                                    .padding(.bottom)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack {
                    DeferredTextField(label: "Name", text: $book.name)
                    
                    if let subtitle = book.string(forKey: "subtitle") {
                        Text(subtitle)
                            .font(.subheadline)
                    }
                }
                .padding(.vertical)
                
            }
        }
        .onDisappear(perform: handleDisappear)
    }
    
    func handleDisappear() {
        model.save()
    }
}

struct RawPropertyView: View {
    let key: String
    let value: Any
    
    var body: some View {
        let string: String
        if let list = value as? [String] {
            string = list.joined(separator: ", ")
        } else {
            string = String(describing: value)
        }
        
        return VStack(alignment: .leading) {
        if !string.isEmpty {
            Text(key)
                .foregroundColor(.secondary)
            Text(string)
        }
        }
    }
}
