// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 17/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import XCTest

class BookishUITests: UITests {
    
    override func setUp() {
        continueAfterFailure = false

    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func makeEmptyDocument() -> XCUIElement {
        let count = application.windows.count
        
        // make a new document
        clickMenuItem(at: ["New", "Collection"])
        
        // should now have an untitled document
        XCTAssertEqual(XCUIApplication().windows.count, count + 1)
        
        return application.windows.allElementsBoundByIndex.last!
    }
    
    func closeFrontDocument() {
        clickMenuItem(at: ["File", "Close"])
        if button("Delete").exists {
            clickButton("Delete")
        }
    }
    
    func testNewDocument() {
        launch(arguments: ["--no-blank-document"])
        let _ = makeEmptyDocument()
    }
    
    func testCloseDocument() {
        launch()
        closeFrontDocument()
        XCTAssertEqual(application.windows.count, 0)
    }

    func testAddingBook() {
        launch()
        let count = tableRowCount("books")
        
        // button
        clickButton("button.InsertItem")
        XCTAssertEqual(count + 1, tableRowCount("books"))

        // toolbar button
        clickToolbarButton("New")
        XCTAssertEqual(count + 2, tableRowCount("books"))

        // menu item
        clickMenuItem(at: ["New", "Book"])
        XCTAssertEqual(count + 3, tableRowCount("books"))
    }

    func testRemovingBook() {
        launch(arguments:["--test-document"])
        let count = tableRowCount("books")
        
        // button
        clickTableRow(0, table: "books")
        clickButton("button.RemoveItem")
        XCTAssertEqual(count - 1, tableRowCount("books"))

        // toolbar button
        clickTableRow(0, table: "books")
        clickToolbarButton("Remove")
        XCTAssertEqual(count - 2, tableRowCount("books"))

        // menu item
        clickTableRow(0, table: "books")
        clickMenuItem("Delete Book")
        XCTAssertEqual(count - 3, tableRowCount("books"))
    }


    func testRenamingChangesIndex() {
        launch(arguments:["--test-document"])
        let window = application.windows["Untitled"]
        clickTableRow(0, table: "books")
        let field = window.textFields["title"]
        field.click()
        field.typeKey("a", modifierFlags: .command)
        field.typeText("Book Title")
        clickTableRow(0, table: "books")
        XCTAssertEqual(tableRowValue(0, table: "books"), "Book Title")
    }
    
    func testAddingPerson() {
        launch(arguments:["--test-document"])
        let count = tableRowCount("book-details")
        with(scope: table("book-details")) {
            clickField("person-0")
        }

        // button
        clickButton("button.PopupPersonMenu")
        clickMenuItem("Editor")
        XCTAssertEqual(count + 1, tableRowCount("book-details"))
        print("tested button")

        // toolbar
        clickToolbarButton("Add")
        clickMenuItem("Author")
        XCTAssertEqual(count + 2, tableRowCount("book-details"))
        print("tested toolbar")

        // menu
        clickMenuItem(at: ["Book", "Author"])
        XCTAssertEqual(count + 3, tableRowCount("book-details"))
        print("tested menu")
    }

    func testRemovingPerson() {
        launch(arguments:["--test-document"])
        let count = tableRowCount("book-details")
        
        // button
        with(scope: table("book-details")) { clickField("person-2") }
        clickButton("button.RemovePerson")
        XCTAssertEqual(count - 1, tableRowCount("book-details"))
        
        // toolbar
        with(scope: table("book-details")) { clickField("person-1") }
        clickToolbarButton("Remove", count: 1)
        XCTAssertEqual(count - 2, tableRowCount("book-details"))
        
        // menu
        with(scope: table("book-details")) { clickField("person-0") }
        clickMenuItem("Remove Person")
        XCTAssertEqual(count - 3, tableRowCount("book-details"))
    }
    
    func testRemoveBookState() {
        launch(arguments: ["--test-document"])
        clickTableRow(0, table: "books")
        XCTAssertTrue(button("button.RemoveItem").isEnabled)
        XCTAssertTrue(toolbarButton("Remove").isEnabled)
        XCTAssertTrue(menuItem("Delete Book").isEnabled)
        table("books").click()
        XCTAssertFalse(button("button.RemoveItem").isEnabled)
        XCTAssertFalse(toolbarButton("Remove").isEnabled)
        clickMenuItem("Book")
        XCTAssertFalse(menuItem("Delete Book").isEnabled)
    }

    func testAddPersonState() {
        launch(arguments: ["--test-document"])
        clickTableRow(0, table: "books")
        XCTAssertTrue(menuItem(at: ["Add Person", "Author"]).isEnabled)
        XCTAssertTrue(toolbarButton("Add").isEnabled)
        with(scope: table("book-details")) {
            clickField("person-0")
        }
        XCTAssertTrue(button("button.PopupPersonMenu").isEnabled)
        table("books").click()
        clickMenuItem("Add Person")
        XCTAssertFalse(menuItem(at: ["Add Person", "Author"]).isEnabled)
        XCTAssertFalse(toolbarButton("Add").isEnabled)
    }

    func testRemovePersonState() {
        launch(arguments: ["--test-document"])
        clickTableRow(0, table: "books")
        XCTAssertFalse(menuItem("Remove Person").isEnabled)
        XCTAssertFalse(toolbarButton("Remove", count: 1).isEnabled)
        with(scope: table("book-details")) {
            clickField("person-0")
        }
        clickMenuItem("Book")
        XCTAssertTrue(menuItem("Remove Person").isEnabled)
        XCTAssertTrue(toolbarButton("Remove", count: 1).isEnabled)
        XCTAssertTrue(button("button.RemovePerson").isEnabled)
        
        clickTableRow(1, table: "books")
        table("books").click()
        clickMenuItem("Book")
        XCTAssertFalse(menuItem("Remove Person").isEnabled)
        XCTAssertFalse(toolbarButton("Remove", count: 1).isEnabled)
    }

}
