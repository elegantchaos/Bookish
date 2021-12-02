// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 12/01/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

import SwiftUI

struct BookView: View {
    @Environment(\.horizontalSizeClass) var size
    @Environment(\.managedObjectContext) var managedObjectContext
    @EnvironmentObject var model: Model
    @ObservedObject var book: CDRecord
    @ObservedObject var fields: FieldList
    @State var selection: String?
    
    @AppStorage("showLinks") var showLinks = true
    @AppStorage("showRaw") var  showRaw = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if size == .compact {
                    AsyncImageView(model.image(for: book, usePlacholder: false))
                        .frame(maxWidth: 256, maxHeight: 256)
                        .padding(.bottom)

                    HStack(alignment: .top, spacing: 0) {
                        Image(systemName: "note.text")

                        TextEditor(text: book.binding(forProperty: "notes"))
                            .lineLimit(10)
                    }
                } else {
                    HStack(alignment: .top) {
                        Label {
                            TextField("notes", text: book.binding(forProperty: "notes"))
                                .fixedSize(horizontal: true, vertical: false)
                        } icon: {
                            Image(systemName: "note.text")
                        }

                        AsyncImageView(model.image(for: book, usePlacholder: false))
                            .frame(maxWidth: 256, maxHeight: 256)
                    }
                }
                
                FieldsView(record: book, fields: fields)
                    .padding(.bottom)

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
                .padding(.vertical)
                
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
                .padding(.vertical)
            }
        }
        .padding()
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
