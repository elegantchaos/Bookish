// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 12/01/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

class ExportController: ObservableObject {
    let model: ModelController

    init(model: ModelController) {
        self.model = model
    }
    
    func export(_ root: CDRecord) throws -> Data {
        let dictionary = root.asInterchange()
        return try ExtendedJSONSerialization.data(withJSONObject: dictionary, options: [.prettyPrinted, .sortedKeys])
    }
}
