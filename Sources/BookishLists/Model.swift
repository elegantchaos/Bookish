// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/01/2021.
//  All code (c) 2021 - present day, Sam Deane.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI
import KeyValueStore

extension String {
    static let placeholderKey = "Placeholder"
}

class Model: ObservableObject {
    @Published var placeholder = "Placeholder"

    init() {
    }
    
    init(from store: KeyValueStore) {
        let decoder = JSONDecoder()
        placeholder = store.string(forKey: .placeholderKey) ?? ""
        migrate(from: store)
    }
    
    var appName: String { "Samedi's Market Manager" }
    
    func migrate(from store: KeyValueStore) {
    }
    
    func save(to store: KeyValueStore) {
        
        let encoder = JSONEncoder()
    }
    

}
