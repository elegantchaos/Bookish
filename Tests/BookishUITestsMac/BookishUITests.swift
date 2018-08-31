// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 17/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import XCTest

class BookishUITests: XCTestCase {
    let application = XCUIApplication()
    
    override func setUp() {
        continueAfterFailure = false

        // launch with the --reset flag to ensure that we start in a known state
        application.launchArguments = ["-NSTreatUnknownArgumentsAsOpen", "NO", "-ApplePersistenceIgnoreState", "YES"]
        application.launch()
        XCTAssertEqual(application.windows.count, 1)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func makeEmptyDocument() -> XCUIElement {
        let count = application.windows.count
        
        // make a new document
        let menuBarsQuery = XCUIApplication().menuBars
        let newMenuItem = menuBarsQuery/*@START_MENU_TOKEN@*/.menuItems["New"]/*[[".menuBarItems[\"File\"]",".menus.menuItems[\"New\"]",".menuItems[\"New\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/
        newMenuItem.click()
        
        // should now have an untitled document
        XCTAssertEqual(XCUIApplication().windows.count, count + 1)
        
        return application.windows.allElementsBoundByIndex.last!
    }
    
    func closeFrontDocument() {
        application.menuBars.menuBarItems["File"].menuItems["Close"].click()
    }
    
    func testNewDocument() {
        XCTAssertEqual(application.windows.count, 1)
        let _ = makeEmptyDocument()
        XCTAssertEqual(application.windows.count, 2)
    }
    
    func testCloseDocument() {
        closeFrontDocument()
        XCTAssertEqual(application.windows.count, 0)
    }
    
    func testAddBookButton() {
        let window = application.windows["Untitled"]
        window.buttons["add-book"].click()
        let index = window.tables["books"]
        let item = index.staticTexts.element(boundBy: 0)
        XCTAssertEqual(item.value as! String, "Untitled 0")
        item.click()
    }
    
    

}
