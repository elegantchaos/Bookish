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
        clickButton("button.InsertBook")
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
        clickButton("button.RemoveBook")
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
        let count = tableRowCount("details")
        with(scope: table("details")) {
            clickField("person-0")
        }

        // button
        clickButton("button.ShowAddPerson")
        clickMenuItem("Editor")
        XCTAssertEqual(count + 1, tableRowCount("details"))

        // toolbar
        clickToolbarButton("Add")
        clickMenuItem("Author")
        XCTAssertEqual(count + 2, tableRowCount("details"))
        
        // menu
        clickMenuItem(at: ["Add Person", "Author"])
        XCTAssertEqual(count + 3, tableRowCount("details"))
    }

}
