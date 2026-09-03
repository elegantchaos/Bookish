// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/12/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Testing

@testable import BookishCleanup

struct SeriesScannerTests {
  typealias Book = SeriesCleaner.Book

  func check(book: Book, seriesName: String, position: Int) -> Bool {
    book.series == seriesName && book.position == position
  }

  func cleanBook(title: String, subtitle: String? = nil) -> Book? {
    let cleaner = SeriesCleaner()
    let book = cleaner.cleanup(
      book: Book(title: title, subtitle: subtitle ?? "", series: "", position: 0))
    return book
  }

  func scanBook(title: String, subtitle: String? = nil) throws -> Book {
    try #require(cleanBook(title: title, subtitle: subtitle))
  }

  @Test

  func coverage() {
    let _ = SeriesDetector().detect(name: "", subtitle: "")
  }

  @Test

  func noMatch() {
    // name, series and book all in the title
    let book = cleanBook(title: "Nothing To Match Here (Oh No)")
    #expect(book == nil)
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
  //        #expect(book.name == "Test Book")
  //        #expect(check(book: book, series: series, position: 2))
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
  @Test
  func case1() throws {
    // name, series and book all in the title
    let book = try scanBook(title: "The Amtrak Wars: Cloud Warrior Bk. 1")
    #expect(book.title == "Cloud Warrior")
    #expect(check(book: book, seriesName: "The Amtrak Wars", position: 1))
  }

  @Test
  func case2() throws {
    // name series in the title, series in the subtitle
    let book = try scanBook(title: "Carpe Jugulum (Discworld Novel)", subtitle: "Discworld Novel")
    #expect(book.title == "Carpe Jugulum")
    #expect(check(book: book, seriesName: "Discworld Novel", position: 0))

  }

  @Test
  func case3() throws {
    // series in brackets with "S." at the end
    let book = try scanBook(title: "Effendi: The Second Arabesk (Arabesk S.)")
    #expect(book.title == "Effendi: The Second Arabesk")
    #expect(check(book: book, seriesName: "Arabesk", position: 0))

  }

  @Test
  func case4() throws {
    // series in brackets and subtitle, but with "The" appended in the title
    let book = try scanBook(
      title: "The Darkest Road (The Fionavar Tapestry)", subtitle: "Fionavar Tapestry")
    #expect(book.title == "The Darkest Road")
    #expect(check(book: book, seriesName: "Fionavar Tapestry", position: 0))

    let book2 = try scanBook(
      title: "The Darkest Road (Fionavar Tapestry)", subtitle: "The Fionavar Tapestry")
    #expect(book2.title == "The Darkest Road")
    #expect(check(book: book2, seriesName: "Fionavar Tapestry", position: 0))
  }

  @Test
  func case5() throws {
    // series and book in the subtitle, in brackets
    let book = try scanBook(title: "Ancillary Justice", subtitle: "(Imperial Radch Book 1)")
    #expect(book.title == "Ancillary Justice")
    #expect(check(book: book, seriesName: "Imperial Radch", position: 1))
  }

  @Test
  func case6() throws {
    // series in brackets in the title, and in the subtitle, but with "A" appended in the title
    let book = try scanBook(
      title: "The Colour of Magic (A Discworld Novel)", subtitle: "Discworld Novel")
    #expect(book.title == "The Colour of Magic")
    #expect(check(book: book, seriesName: "Discworld Novel", position: 0))

    let book2 = try scanBook(
      title: "The Colour of Magic (Discworld Novel)", subtitle: "A Discworld Novel")
    #expect(book2.title == "The Colour of Magic")
    #expect(check(book: book2, seriesName: "Discworld Novel", position: 0))
  }

  @Test
  func case7() throws {
    // series, name and number in the title, series also in the subtitle
    let book = try scanBook(
      title: "Chung Kuo: Beneath the Tree of Heaven Bk. 5", subtitle: "Chung Kuo")
    #expect(book.title == "Beneath the Tree of Heaven")
    #expect(check(book: book, seriesName: "Chung Kuo", position: 5))
  }

  @Test
  func case8() throws {
    // name and book, series in brackets with "S." at the end
    let book = try scanBook(title: "Name Book 2 (Series S.)")
    #expect(book.title == "Name")
    #expect(check(book: book, seriesName: "Series", position: 2))
  }

  @Test
  func case9() throws {
    // series in brackets with "S." at the end, also set as the subtitle
    let book = try scanBook(title: "Effendi: The Second Arabesk (Arabesk S.)", subtitle: "Arabesk")
    #expect(book.title == "Effendi: The Second Arabesk")
    #expect(book.subtitle == "")
    #expect(check(book: book, seriesName: "Arabesk", position: 0))
  }

  @Test
  func case10() throws {
    // series in brackets with "S." at the end, also set as the subtitle
    let book = try scanBook(
      title: "The Better Part of Valour: A Confederation Novel (Valour Confederation Book 2)")
    #expect(book.title == "The Better Part of Valour: A Confederation Novel")
    #expect(book.subtitle == "")
    #expect(check(book: book, seriesName: "Valour Confederation", position: 2))
  }

  @Test
  func case11() throws {
    // subtitle is name of series, with number at the end
    let book = try scanBook(title: "The Amber Citadel", subtitle: "Jewelfire Trilogy 1")
    #expect(book.title == "The Amber Citadel")
    #expect(book.subtitle == "")
    #expect(check(book: book, seriesName: "Jewelfire Trilogy", position: 1))
  }

  @Test
  func case12() throws {
    let book = try scanBook(
      title: "A Dance With Dragons: Part 1 Dreams and Dust (A Song of Ice and Fire, Book 5)")
    #expect(book.title == "A Dance With Dragons: Part 1 Dreams and Dust")
    #expect(book.subtitle == "")
    #expect(check(book: book, seriesName: "A Song of Ice and Fire", position: 5))
  }

  @Test
  func case13() throws {
    let book = try scanBook(
      title: "A Storm of Swords: Steel and Snow (A Song of Ice and Fire, Book 3 Part 1)",
      subtitle: "A Song of Ice and Fire, Book 3 Part 1")
    #expect(book.title == "A Storm of Swords: Steel and Snow Part 1")
    #expect(book.subtitle == "")
    #expect(check(book: book, seriesName: "A Song of Ice and Fire", position: 3))
  }

  @Test
  func case14() throws {
    seriesDetectorChannel.enabled = true
    let book = try scanBook(
      title: "A Dance With Dragons: Part 2 After The Feast",
      subtitle: "(A Song of Ice and Fire, Book 5)")
    #expect(book.title == "A Dance With Dragons: Part 2 After The Feast")
    #expect(book.subtitle == "")
    #expect(check(book: book, seriesName: "A Song of Ice and Fire", position: 5))
  }

  @Test
  func case15() throws {
    seriesDetectorChannel.enabled = true
    let book = try scanBook(title: "The Fuller Memorandum: Book 3 in The Laundry Files")
    #expect(book.title == "The Fuller Memorandum")
    #expect(book.subtitle == "")
    #expect(check(book: book, seriesName: "The Laundry Files", position: 3))
  }

  @Test
  func case16() throws {
    seriesDetectorChannel.enabled = true
    let book = try scanBook(
      title: "The Name of the Wind: The Kingkiller Chronicle: Book 1 (Kingkiller Chonicles)")
    #expect(book.title == "The Name of the Wind")
    #expect(book.subtitle == "")
    #expect(check(book: book, seriesName: "The Kingkiller Chronicle", position: 1))
  }

}
