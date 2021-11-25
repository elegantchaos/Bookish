// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 24/03/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

public struct BookishImporter {
    public static func urlForSample(withName name: String) -> URL {
        Bundle.module.url(forResource: name, withExtension: "xml")!
    }
    
    public static func dictionaryForSample(withName name: String) -> Any {
        let url = urlForSample(withName: name)
        let data = try! Data(contentsOf: url)
        let decoded = try! PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        return decoded
    }
}

