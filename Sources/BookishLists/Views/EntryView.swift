// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 12/01/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

import SwiftUI

//struct EntryView: View {
//    @Environment(\.managedObjectContext) var managedObjectContext
//    @EnvironmentObject var model: Model
//    @ObservedObject var entry: CDEntry
//    @State var title = ""
//    
//    var body: some View {
//        ScrollView {
//            VStack {
//                BookView(book: entry.book)
//
//                
//                DisclosureGroup("Raw List Properties") {
//                    VStack {
//                        let keys = entry.sortedKeys
//                        ForEach(keys, id: \.self) { key in
//                            HStack {
//                                if let value = entry.property(forKey: key) {
//                                    let string = String(describing: value)
//                                    if !string.isEmpty {
//                                        Text(key)
//                                        Spacer()
//                                        Text(string)
//                                    }
//                                }
//                            }
//                        }
//                    }
//                }
//                .padding()
//            }
//        }
//        .navigationBarTitleDisplayMode(.large)
//                .toolbar {
//                    ToolbarItem(placement: .principal) {
//                        VStack {
//                            TextField("Name", text: $title, onCommit: handleCommit)
//                                .font(.title)
//                            
//                            if let subtitle = entry.book.string(forKey: "subtitle") {
//                                Text(subtitle)
//                            }
//                        }
//                        .padding(.vertical)
//                        
//                    }
//                }
//        .onAppear(perform: handleAppear)
//        .onDisappear(perform: handleDisappear)
//    }
//    
//    func handleAppear() {
//        title = entry.book.name
//    }
//    
//    func handleDisappear() {
//        model.save()
//    }
//    
//    func handleCommit() {
//        entry.book.name = title
//    }
//}
