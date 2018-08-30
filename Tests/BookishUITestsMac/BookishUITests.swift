// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 17/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import XCTest

class BookishUITests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()
        XCUIElement.perform(withKeyModifiers: .option) {
            XCUIApplication().menuBars/*@START_MENU_TOKEN@*/.menuBarItems["File"].menuItems["Close All"]/*[[".menuBarItems[\"File\"]",".menus.menuItems[\"Close All\"]",".menuItems[\"Close All\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[2,0]]@END_MENU_TOKEN@*/.click()
        }
        XCTAssertEqual(XCUIApplication().windows.count, 0)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testNewDocument() {
        // shouldn't have an untitled document at this point
        let window = XCUIApplication().windows["Untitled"]
        XCTAssertFalse(window.exists)

        // make a new document
        let menuBarsQuery = XCUIApplication().menuBars
        let newMenuItem = menuBarsQuery/*@START_MENU_TOKEN@*/.menuItems["New"]/*[[".menuBarItems[\"File\"]",".menus.menuItems[\"New\"]",".menuItems[\"New\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/
        newMenuItem.click()

        // should now have an untitled document
        XCTAssertTrue(window.exists)
        XCTAssertEqual(XCUIApplication().windows.count, 1)
//
//        let untitledWindow = XCUIApplication().windows["Untitled"]
//        untitledWindow.click()
//
//        let automatictablecolumnidentifier0Table = untitledWindow/*@START_MENU_TOKEN@*/.tables.containing(.tableColumn, identifier:"AutomaticTableColumnIdentifier.0").element/*[[".splitGroups",".scrollViews.tables.containing(.tableColumn, identifier:\"AutomaticTableColumnIdentifier.0\").element",".tables.containing(.tableColumn, identifier:\"AutomaticTableColumnIdentifier.0\").element"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/
//        automatictablecolumnidentifier0Table.click()
//        untitledWindow.click()
//
//        let splitGroupsQuery = untitledWindow.splitGroups
//        splitGroupsQuery.children(matching: .textField)["No Selection"].click()
//
//        let cell = untitledWindow/*@START_MENU_TOKEN@*/.tables.containing(.tableColumn, identifier:"AutomaticTableColumnIdentifier.0")/*[[".splitGroups",".scrollViews.tables.containing(.tableColumn, identifier:\"AutomaticTableColumnIdentifier.0\")",".tables.containing(.tableColumn, identifier:\"AutomaticTableColumnIdentifier.0\")"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/.tableRows.children(matching: .cell).element
//        cell.typeText("NewBook")
//        splitGroupsQuery.children(matching: .textField).element(boundBy: 1).click()
//        cell.typeText("New Subtitle")
//        automatictablecolumnidentifier0Table.click()

    }
    
    

}
