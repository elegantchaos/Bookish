// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 12/01/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

import SwiftUI

struct BookView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @EnvironmentObject var model: Model
    @ObservedObject var entry: CDEntry
    @ObservedObject var book: CDBook
    @State var title = ""
    
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
                    } icon: {
                        Image(systemName: "note.text")
                    }
                    
                    Spacer()
                }

                Spacer()
                
                AsyncImageView(model.image(for: book))
                    .frame(maxWidth: 256, maxHeight: 256)
            }
            .padding()

            DisclosureGroup("Raw Properties") {
                VStack {
                    let raw: [String:Any] = book.dict(forKey: "raw") ?? [:]
                    let keys = raw.keys.sorted()
                    ForEach(keys, id: \.self) { key in
                        HStack {
                            if let value = raw[key] {
                                let string = String(describing: value)
                                if !string.isEmpty {
                                    Text(key)
                                    Spacer()
                                    Text(string)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
        }
        .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        VStack {
                            TextField("Name", text: $title, onCommit: handleCommit)
                                .font(.title)
                            
                            if let subtitle = book.string(forKey: "subtitle") {
                                Text(subtitle)
                            }
                        }
                        .padding(.vertical)
                        
                    }
                }
        .onAppear(perform: handleAppear)
        .onDisappear(perform: handleDisappear)
    }
    
    func handleAppear() {
        title = book.name
    }
    
    func handleDisappear() {
        model.save()
    }
    
    func handleCommit() {
        book.name = title
    }
}
