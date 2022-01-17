// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 12/01/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI
import Bundles

class ExportController: ObservableObject {
    let model: ModelController
    let info: BundleInfo
    
    init(model: ModelController, info: BundleInfo) {
        self.model = model
        self.info = info
    }
    
    func export(_ root: CDRecord) throws -> Data {
        let dictionary = root.asInterchange()
        
        let wrapper: [String:Any] = [
            "type": [
                "format": "com.elegantchaos.bookish.list",
                "version": 1,
                "variant": "compact"
            ],
            "creator": [
                "id": info.id,
                "version": info.version.asString,
                "build": info.build,
                "commit": info.commit
            ],
            "content": dictionary
        ]
        
        return try JSONSerialization.data(withJSONObject: wrapper, options: [.prettyPrinted, .sortedKeys])
    }
}
