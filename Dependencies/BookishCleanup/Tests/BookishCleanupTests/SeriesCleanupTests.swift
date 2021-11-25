// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/12/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-


import XCTest

@testable import BookishCleanup

class SeriesScannerTests: XCTestCase {
    typealias Book = SeriesCleaner.Book
    
    func check(book: Book, seriesName: String, position: Int) -> Bool {
        XCTAssertEqual(book.series, seriesName)
        XCTAssertEqual(book.position, position)
        return (book.series == seriesName) && (book.position == position)
    }

    func cleanBook(title: String, subtitle: String? = nil) -> Book? {
        let cleaner = SeriesCleaner()
        let book = cleaner.cleanup(book: Book(title: title, subtitle: subtitle ?? "", series: "", position: 0))
        return book
    }

    func scanBook(title: String, subtitle: String? = nil) -> Book {
        let book = cleanBook(title: title, subtitle: subtitle)
        XCTAssertNotNil(book)
        return book!
    }

    func testCoverage() {
        let _ = SeriesDetector().detect(name: "", subtitle: "")
    }

    func testNoMatch() {
        // name, series and book all in the title
        let book = cleanBook(title: "Nothing To Match Here (Oh No)")
        XCTAssertNil(book)
    }
//
//    func testExistingSeries() {
//        // name, series and book all in the title
//        let container = makeTestContainer()
//        let context = container.managedObjectContext
//
//        let series = Series(context: context)
//        series.name = "Test Series"
//        let book = Book(context: context)
//        book.name = "Test Series: Test Book No. 2"
//
//        let scanner = SeriesScanner(context: context)
//        scanner.run()
//        XCTAssertEqual(book.name, "Test Book")
//        XCTAssertTrue(check(book: book, series: series, position: 2))
//    }
//
//    func testAction() {
//        let performed = expectation(description: "performed")
//        let manager = ActionManager()
//        let container = makeTestContainer()
//        manager.register([ScanSeriesAction(identifier: "ScanSeries")])
//        let info = ActionInfo(sender: self)
//        info[ActionContext.model] = container.managedObjectContext
//        info.registerNotification { (stage, context) in
//            if stage == .didPerform {
//                performed.fulfill()
//            }
//        }
//
//        manager.perform(identifier: "ScanSeries", info: info)
//        wait(for: [performed], timeout: 1.0)
//    }
//
    func test1() {
        // name, series and book all in the title
        let book = scanBook(title: "The Amtrak Wars: Cloud Warrior Bk. 1")
        XCTAssertEqual(book.title, "Cloud Warrior")
        XCTAssertTrue(check(book: book, seriesName: "The Amtrak Wars", position: 1))
    }
    
    func test2() {
        // name series in the title, series in the subtitle
        let book = scanBook(title: "Carpe Jugulum (Discworld Novel)", subtitle: "Discworld Novel")
        XCTAssertEqual(book.title, "Carpe Jugulum")
        XCTAssertTrue(check(book: book, seriesName: "Discworld Novel", position: 0))

    }

    func test3() {
        // series in brackets with "S." at the end
        let book = scanBook(title: "Effendi: The Second Arabesk (Arabesk S.)")
        XCTAssertEqual(book.title, "Effendi: The Second Arabesk")
        XCTAssertTrue(check(book: book, seriesName: "Arabesk", position: 0))
        
    }

    func test4() {
        // series in brackets and subtitle, but with "The" appended in the title
        let book = scanBook(title: "The Darkest Road (The Fionavar Tapestry)", subtitle: "Fionavar Tapestry")
        XCTAssertEqual(book.title, "The Darkest Road")
        XCTAssertTrue(check(book: book, seriesName: "Fionavar Tapestry", position: 0))

        let book2 = scanBook(title: "The Darkest Road (Fionavar Tapestry)", subtitle: "The Fionavar Tapestry")
        XCTAssertEqual(book2.title, "The Darkest Road")
        XCTAssertTrue(check(book: book2, seriesName: "Fionavar Tapestry", position: 0))
    }

    func test5() {
        // series and book in the subtitle, in brackets
        let book = scanBook(title: "Ancillary Justice", subtitle: "(Imperial Radch Book 1)")
        XCTAssertEqual(book.title, "Ancillary Justice")
        XCTAssertTrue(check(book: book, seriesName: "Imperial Radch", position: 1))
    }
    
    func test6() {
        // series in brackets in the title, and in the subtitle, but with "A" appended in the title
        let book = scanBook(title: "The Colour of Magic (A Discworld Novel)", subtitle: "Discworld Novel")
        XCTAssertEqual(book.title, "The Colour of Magic")
        XCTAssertTrue(check(book: book, seriesName: "Discworld Novel", position: 0))

        let book2 = scanBook(title: "The Colour of Magic (Discworld Novel)", subtitle: "A Discworld Novel")
        XCTAssertEqual(book2.title, "The Colour of Magic")
        XCTAssertTrue(check(book: book2, seriesName: "Discworld Novel", position: 0))
    }

    func test7() {
        // series, name and number in the title, series also in the subtitle
        let book = scanBook(title: "Chung Kuo: Beneath the Tree of Heaven Bk. 5", subtitle: "Chung Kuo")
        XCTAssertEqual(book.title, "Beneath the Tree of Heaven")
        XCTAssertTrue(check(book: book, seriesName: "Chung Kuo", position: 5))
    }

    func test8() {
        // name and book, series in brackets with "S." at the end
        let book = scanBook(title: "Name Book 2 (Series S.)")
        XCTAssertEqual(book.title, "Name")
        XCTAssertTrue(check(book: book, seriesName: "Series", position: 2))
    }

    func test9() {
        // series in brackets with "S." at the end, also set as the subtitle
        let book = scanBook(title: "Effendi: The Second Arabesk (Arabesk S.)", subtitle: "Arabesk")
        XCTAssertEqual(book.title, "Effendi: The Second Arabesk")
        XCTAssertEqual(book.subtitle, "")
        XCTAssertTrue(check(book: book, seriesName: "Arabesk", position: 0))
    }

    func test10() {
        // series in brackets with "S." at the end, also set as the subtitle
        let book = scanBook(title: "The Better Part of Valour: A Confederation Novel (Valour Confederation Book 2)")
        XCTAssertEqual(book.title, "The Better Part of Valour: A Confederation Novel")
        XCTAssertEqual(book.subtitle, "")
        XCTAssertTrue(check(book: book, seriesName: "Valour Confederation", position: 2))
    }

    func test11() {
        // subtitle is name of series, with number at the end
        let book = scanBook(title: "The Amber Citadel", subtitle: "Jewelfire Trilogy 1")
        XCTAssertEqual(book.title, "The Amber Citadel")
        XCTAssertEqual(book.subtitle, "")
        XCTAssertTrue(check(book: book, seriesName: "Jewelfire Trilogy", position: 1))
    }
    
    func test12() {
        let book = scanBook(title: "A Dance With Dragons: Part 1 Dreams and Dust (A Song of Ice and Fire, Book 5)")
        XCTAssertEqual(book.title, "A Dance With Dragons: Part 1 Dreams and Dust")
        XCTAssertEqual(book.subtitle, "")
        XCTAssertTrue(check(book: book, seriesName: "A Song of Ice and Fire", position: 5))
    }

    func test13() {
        let book = scanBook(title: "A Storm of Swords: Steel and Snow (A Song of Ice and Fire, Book 3 Part 1)", subtitle: "A Song of Ice and Fire, Book 3 Part 1")
        XCTAssertEqual(book.title, "A Storm of Swords: Steel and Snow Part 1")
        XCTAssertEqual(book.subtitle, "")
        XCTAssertTrue(check(book: book, seriesName: "A Song of Ice and Fire", position: 3))
    }

    func test14() {
        seriesDetectorChannel.enabled = true
        let book = scanBook(title: "A Dance With Dragons: Part 2 After The Feast", subtitle: "(A Song of Ice and Fire, Book 5)")
        XCTAssertEqual(book.title, "A Dance With Dragons: Part 2 After The Feast")
        XCTAssertEqual(book.subtitle, "")
        XCTAssertTrue(check(book: book, seriesName: "A Song of Ice and Fire", position: 5))
    }

    func test15() {
        seriesDetectorChannel.enabled = true
        let book = scanBook(title: "The Fuller Memorandum: Book 3 in The Laundry Files")
        XCTAssertEqual(book.title, "The Fuller Memorandum")
        XCTAssertEqual(book.subtitle, "")
        XCTAssertTrue(check(book: book, seriesName: "The Laundry Files", position: 3))
    }

    func test16() {
        seriesDetectorChannel.enabled = true
        let book = scanBook(title: "The Name of the Wind: The Kingkiller Chronicle: Book 1 (Kingkiller Chonicles)")
        XCTAssertEqual(book.title, "The Name of the Wind")
        XCTAssertEqual(book.subtitle, "")
        XCTAssertTrue(check(book: book, seriesName: "The Kingkiller Chronicle", position: 1))
    }

    

}


