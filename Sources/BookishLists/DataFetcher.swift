// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 16/05/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/**
 Simple abstraction for fetching data synchronously from a URL and returning it as
 dictionary data.
 
 This mainly exists to allow us to use dependency injection to swap in a non network-dependent
 fetcher for testing purposes.
 */

public class DataFetcher {
    func info(for url: URL) -> [String:Any]? {
        return nil
    }
}

/**
 Default fetcher which grabs data from the URL and tries to parse it as JSON.
 */

public class JSONDataFetcher: DataFetcher {
    override func info(for url: URL) -> [String:Any]? {
        guard
            let data = try? Data(contentsOf: url),
            let parsed = try? JSONSerialization.jsonObject(with: data, options: []),
            let info = parsed as? [String:Any]
            else {
                return nil
        }
        
        return info
    }
}

/**
 Test fetcher which ignores the URL and just returns the data it's been given.
 Useful for testing.
 */

public class TestDataFetcher: DataFetcher {
    let data: [String:Any]?
    
    init(data: [String:Any]? = nil) {
        self.data = data
    }
    
    override func info(for url: URL) -> [String : Any]? {
        return data
    }
}
