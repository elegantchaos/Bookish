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
    
    public init(_ data: Data) throws {
        let decoder = JSONDecoder()
        self = try decoder.decode(InterchangeFileHeader.self, from: data)
    }
    
    let type: InterchangeFileType
    let creator: InterchangeCreator
    
    var isValid: Bool {
        return !type.format.isEmpty
    }
}

public struct InterchangeFile {
    
    public init(type: InterchangeFileType, creator: InterchangeCreator, content: InterchangeContainer, root: String? = nil) {
        self.header = .init(type: type, creator: creator)
        self.content = content
        self.root = root
    }
    
    public init(_ data: Data) throws {
        let header = try InterchangeFileHeader(data)
        let decoded = try JSONSerialization.jsonObject(with: data, options: [.json5Allowed])
        
        guard let dictionary = decoded as? [String:Any], let content = dictionary["content"] as? [Any] else { throw InterchangeError.contentDecodingFailed }
        self.header = header
        self.content = try InterchangeContainer(content)
        self.root = dictionary["root"] as? String
    }

    let header: InterchangeFileHeader
    let content: InterchangeContainer
    let root: String?
    
    public static func isValidFile(at url: URL) -> Bool {
        guard let data = try? Data(contentsOf: url) else { return false }
        return isValidFile(in: data)
    }
    
    public static func isValidFile(in data: Data) -> Bool {
        do {
            let header = try InterchangeFileHeader(data)
            return header.isValid
        } catch {
            return false
        }
    }
    
    func encode() throws -> Data {
        let encoder = JSONEncoder()
        let headerData = try encoder.encode(header)
        
        let decodedHeader = try JSONSerialization.jsonObject(with: headerData, options: .json5Allowed)
        guard var dictionary = decodedHeader as? [String:Any] else { throw InterchangeError.headerDecodingFailed }
        
        let encodedContent = try content.asList()
        dictionary["content"] = encodedContent
        dictionary["root"] = root
        
        let fullData = try JSONSerialization.data(withJSONObject: dictionary, options: [.prettyPrinted, .sortedKeys])
        return fullData
    }
    
}
