// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 12/01/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishCore
import Bundles
import SwiftUI

extension InterchangeContainer {
    enum Depth {
        case shallow
        case oneLevel
        case deep
        
        var nextDepth: Depth {
            switch self {
                case .deep: return .deep
                default: return .shallow
            }
        }
    }
    
    func add(_ object: CDRecord, depth: Depth) {
        if add(object.asInterchange()) == .added {
            if depth != .shallow {
                let items: Set<CDRecord> = object.contents ?? []
                let objects = items.union(object.containedBy ?? [])
                objects.forEach { add($0, depth: depth.nextDepth) }
            }
        }
    }
}

public class ExportController: ObservableObject {
    let model: ModelController
    let info: BundleInfo
    
    public init(model: ModelController, info: BundleInfo) {
        self.model = model
        self.info = info
    }
    
    func export(_ root: CDRecord) throws -> Data {
        let container = InterchangeContainer()
        container.add(root, depth: .shallow)

        let type = InterchangeFileType("com.elegantchaos.bookish.list", version: 1)
        let creator = InterchangeCreator(info)
        let file = InterchangeFile(type: type, creator: creator, content: container, root: root.id)
        return try file.encode()
    }
}
