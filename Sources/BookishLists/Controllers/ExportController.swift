// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 12/01/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI
import Bundles

class InterchangeRecords {
    init() {
        self.index = [:]
    }
    
    var index: [String:CDRecord.InterchangeRecord]
    
    func add(_ object: CDRecord, deep: Bool) {
        if index[object.id] == nil {
            index[object.id] = object.asInterchange()
            print("added \(object.id)")

            if deep {
                object.contents?.forEach { add($0, deep: deep) }
                object.containedBy?.forEach { add($0, deep: deep) }
            }
        }
        
    }
}

class ExportController: ObservableObject {
    let model: ModelController
    let info: BundleInfo
    
    init(model: ModelController, info: BundleInfo) {
        self.model = model
        self.info = info
    }
    
    func export(_ root: CDRecord) throws -> Data {
        let records = InterchangeRecords()
        records.add(root, deep: true)

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
            "content": [
                "items": records.index,
                "root": root.id
            ]
        ]
        
        return try JSONSerialization.data(withJSONObject: wrapper, options: [.prettyPrinted, .sortedKeys])
    }
}
