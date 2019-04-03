// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 03/04/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

extension Bundle {
    var buildString: String {
        guard let version = object(forInfoDictionaryKey: "CFBundleVersion") as? NSString else {
            return ""
        }
        
        return version as String
    }
    
    var buildNumber: Int {
        let version = object(forInfoDictionaryKey: "CFBundleVersion") as? NSNumber
        return version?.intValue ?? 0
    }
}
