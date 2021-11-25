// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Developer on 12/01/2021.
//  All code (c) 2021 - present day, Sam Developer.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import XCTest
import XCTestExtensions

@testable import BookishImporter
import BookishImporterSamples

final class BookishImporterTests: XCTestCase {
    func testExtractSmallSample() {
        let included = [
            "Snow Crash",
            "Cryptonomicon",
            "The Hitchhiker's Guide To The Galaxy",
            "Life, the Universe and Everything (Hitch Hiker's Guide to the Galaxy)",
            "Mostly Harmless (Hitch Hiker's Guide to the Galaxy)",
            "The Restaurant at the End of the Universe (Hitch Hiker's Guide to the Galaxy)",
            "So Long, and Thanks for All the Fish",
            "A Dance With Dragons: Part 1 Dreams and Dust",
            "A Dance With Dragons: Part 2 After The Feast",
            "A Feast for Crows",
            "A Clash of Kings (Song of Ice & Fire S.)",
            "Dreamsongs I:: A Retrospective: Bk. 1",
            "A Game of Thrones",
            "A Storm of Swords: Blood and Gold (A Song of Ice and Fire, Book 3, Part 2)",
            "A Storm of Swords: Steel and Snow (A Song of Ice and Fire, Book 3 Part 1)"
        ]
        
        var simplified: [NSDictionary] = []
        let sample = BookishImporter.dictionaryForSample(withName: "DeliciousFull")
        if let items = sample as? [NSDictionary] {
            for item in items {
                if let title = item["title"] as? String {
                    if included.contains(title) {
                        simplified.append(item)
                    } else {
                        print(title)
                    }
                }
            }
        }
        
        let array = simplified as NSArray
        let data = try! PropertyListSerialization.data(fromPropertyList: array, format: .xml, options: .zero)
        let url = URL(fileURLExpandingPath: "~/Desktop/DeliciousSmall.xml")
        try! data.write(to: url)
    }
}
