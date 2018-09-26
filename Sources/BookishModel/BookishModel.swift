// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 20/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreData
import Logger

let modelChannel = Logger("Model")

public class BookishModel {
    static let version = "1.0.0"
    
    public class func loadModel() -> NSManagedObjectModel {
        guard let url = Bundle(for: self).url(forResource: "Collection", withExtension: "momd") else {
            fatalError("couldn't find model")
        }
        
        guard let model = NSManagedObjectModel(contentsOf: url) else {
            fatalError("couldn't load model")
        }

        modelChannel.debug("loaded collection model")
        return model
    }
}
