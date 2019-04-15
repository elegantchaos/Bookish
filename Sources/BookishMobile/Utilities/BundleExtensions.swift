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
    
    var shortVersion: String {
        guard let version = object(forInfoDictionaryKey: "CFBundleShortVersionString") as? NSString else {
            return ""
        }
        
        return version as String
    }
    
    var fullVersion: String {
        let version = shortVersion
        let build = buildString
        
        return build.isEmpty ? version : "\(version) (\(build))"
    }
    
    var shortName: String {
        guard let version = object(forInfoDictionaryKey: "CFBundleName") as? NSString else {
            return ""
        }
        
        return version as String
    }
    
    var fullName: String {
        let version = fullVersion
        let name = shortName
        return "\(name) \(version)"
    }
    
    var copyright: String {
        guard let version = object(forInfoDictionaryKey: "NSHumanReadableCopyright") as? NSString else {
            return ""
        }
        
        return version as String
    }
}
