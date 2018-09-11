// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 17/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import XCTest

class BookishUITests: XCTestCase {
    let application = XCUIApplication()
    
    override func setUp() {
        continueAfterFailure = false

    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func launch(arguments: [String] = []) {
        // launch with the --reset flag to ensure that we start in a known state
        application.launchArguments = ["-NSTreatUnknownArgumentsAsOpen", "NO", "-ApplePersistenceIgnoreState", "YES", "--ui-testing"]
        application.launchArguments.append(contentsOf: arguments)
        application.launch()
    }
    
    func makeEmptyDocument() -> XCUIElement {
        let count = application.windows.count
        
        // make a new document
        let menuBarsQuery = XCUIApplication().menuBars
        let newMenuItem = menuBarsQuery/*@START_MENU_TOKEN@*/.menuItems["New"]/*[[".menuBarItems[\"File\"]",".menus.menuItems[\"New\"]",".menuItems[\"New\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/
        let newCollectionItem = newMenuItem.menuItems["Collection"]
        newCollectionItem.click()
        
        // should now have an untitled document
        XCTAssertEqual(XCUIApplication().windows.count, count + 1)
        
        return application.windows.allElementsBoundByIndex.last!
    }
    
    func closeFrontDocument() {
        application.menuBars.menuBarItems["File"].menuItems["Close"].click()
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

    func firstIndexItem(window: XCUIElement) -> XCUIElement {
        let index = window.tables["books"]
        let item = index.staticTexts.element(boundBy: 0)
        return item
    }
    
    func indexCount(window: XCUIElement) -> Int {
        let index = window.tables["books"]
        return index.staticTexts.count
    }
    
    func testAddBookButton() {
        launch()
        let window = application.windows["Untitled"]
        window.buttons["button.InsertBook"].click()
        let item = firstIndexItem(window: window)
        XCTAssertEqual(item.value as! String, "Untitled 0")
    }

    func testAddBookToolbarButton() {
        launch()
        let window = application.windows["Untitled"]
        let toolbar = window.toolbars.element(boundBy: 0)
        let button = toolbar.buttons["New"]
        button.click()
        let item = firstIndexItem(window: window)
        XCTAssertEqual(item.value as! String, "Untitled 0")
    }

    func testRemoveBookButton() {
        launch(arguments:["--test-document"])
        let window = application.windows["Untitled"]
        let count = indexCount(window: window)
        let item = firstIndexItem(window: window)
        item.click()
        window.buttons["button.RemoveBook"].click()
        XCTAssertEqual(count - 1, indexCount(window: window))
    }

    func testRemoveBookToolbarButton() {
        launch(arguments:["--test-document"])
        let window = application.windows["Untitled"]
        let count = indexCount(window: window)
        let item = firstIndexItem(window: window)
        item.click()
        let toolbar = window.toolbars.element(boundBy: 0)
        let button = toolbar.children(matching: .button).matching(identifier: "Remove").element(boundBy: 0)
        button.click()
        XCTAssertEqual(count - 1, indexCount(window: window))
    }

    func testRenamingChangesIndex() {
        launch(arguments:["--test-document"])
        let window = application.windows["Untitled"]
        let item = firstIndexItem(window: window)
        item.click()
        let field = window.textFields["title"]
        field.click()
        field.typeKey("a", modifierFlags: .command)
        field.typeText("Book Title")
        item.click()
        XCTAssertEqual(item.value as! String, "Book Title")
    }
    
    func testTest() {
        launch(arguments:["--test-document"])
        
        let untitledWindow = XCUIApplication().windows["Untitled"]
        let toolbarsQuery = untitledWindow.toolbars
        toolbarsQuery.buttons["New"].click()
        untitledWindow/*@START_MENU_TOKEN@*/.tables["books"].staticTexts["Untitled 2"]/*[[".splitGroups",".scrollViews.tables[\"books\"]",".tableRows",".cells.staticTexts[\"Untitled 2\"]",".staticTexts[\"Untitled 2\"]",".tables[\"books\"]"],[[[-1,5,2],[-1,1,2],[-1,0,1]],[[-1,5,2],[-1,1,2]],[[-1,4],[-1,3],[-1,2,3]],[[-1,4],[-1,3]]],[0,0]]@END_MENU_TOKEN@*/.click()
        untitledWindow/*@START_MENU_TOKEN@*/.tables.textFields["value"]/*[[".splitGroups",".scrollViews.tables",".tableRows",".cells.textFields[\"value\"]",".textFields[\"value\"]",".tables"],[[[-1,5,2],[-1,1,2],[-1,0,1]],[[-1,5,2],[-1,1,2]],[[-1,4],[-1,3],[-1,2,3]],[[-1,4],[-1,3]]],[0,0]]@END_MENU_TOKEN@*/.click()
        toolbarsQuery.children(matching: .button).matching(identifier: "Remove").element(boundBy: 1).click()
        toolbarsQuery.buttons["Add"].click()
        toolbarsQuery/*@START_MENU_TOKEN@*/.menuItems["Author"]/*[[".buttons[\"Add\"]",".menus.menuItems[\"Author\"]",".menuItems[\"Author\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/.click()
    }
}
