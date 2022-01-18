// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/01/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Bundles
import Foundation

public struct InterchangeFileHeader: Codable {
    public init(type: InterchangeFileType, creator: InterchangeCreator) {
        self.type = type
        self.creator = creator
    }
    
    let type: InterchangeFileType
    let creator: InterchangeCreator
}

public struct InterchangeFile {
    enum Error: Swift.Error {
        case headerDecodingFailed
    }
    
    public init(type: InterchangeFileType, creator: InterchangeCreator, content: InterchangeContainer, root: String? = nil) {
        self.header = .init(type: type, creator: creator)
        self.content = content
        self.root = root
    }
    
    let header: InterchangeFileHeader
    let content: InterchangeContainer
    let root: String?
    
    func encode() throws -> Data {
        let encoder = JSONEncoder()
        let headerData = try encoder.encode(header)
        
        let decodedHeader = try JSONSerialization.jsonObject(with: headerData, options: .json5Allowed)
        guard var dictionary = decodedHeader as? [String:Any] else { throw Error.headerDecodingFailed }
        
        let content = Array(content.index.values)
        dictionary["content"] = content
        dictionary["root"] = root
        
        let fullData = try JSONSerialization.data(withJSONObject: dictionary, options: [.prettyPrinted, .sortedKeys])
        return fullData
    }
}
