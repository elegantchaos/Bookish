// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 25/11/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-


import Foundation
import Logger
import ElegantStrings
import Expressions

public class PublisherCleaner {
    public init() {
    }

    public struct Book {
        
        public var title: String
        public var subtitle: String
        public var publishers: [String]
        public var series: String

        public init(title: String, subtitle: String, publishers: [String], series: String) {
            self.title = title
            self.subtitle = subtitle
            self.publishers = publishers
            self.series = series
        }
    }
    
    public func cleanup(book input: Book) -> Book? {
        if input.publishers.isEmpty {
            return nil
        }

        var book = input
        for publisher in input.publishers {
            var potentialNames = [publisher]
            if !publisher.hasSuffix(" Books") {
                potentialNames.append("\(publisher) Books")
            }
            
            for name in potentialNames {
                if book.subtitle == name {
                    book.subtitle = ""
                }
                
                let suffix = " (\(name))"
                if let trimmed = book.title.remainder(ifSuffix: suffix) {
                    book.title = String(trimmed)
                }
            }
        }
        
        return book
    }
}
