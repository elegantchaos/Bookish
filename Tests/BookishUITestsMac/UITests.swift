// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/09/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import XCTest

class UITests: XCTestCase {
    let application = XCUIApplication()
    var scope: XCUIElement = XCUIApplication().windows["Untitled"]
    
    var menubar: XCUIElementQuery {
        return application.menuBars
    }
    
    func launch(arguments: [String] = []) {
        // launch with the --reset flag to ensure that we start in a known state
        application.launchArguments = ["-NSTreatUnknownArgumentsAsOpen", "NO", "-ApplePersistenceIgnoreState", "YES", "--ui-testing"]
        application.launchArguments.append(contentsOf: arguments)
        application.launch()
        scope = XCUIApplication().windows.element(boundBy: 0)
    }

    func menuItem(_ name: String) -> XCUIElement {
        var result = scope.toolbars.menuItems[name]
        if !result.exists {
            result = scope.menuItems[name]
        }
        if !result.exists {
            result = menubar.menuItems[name]
        }
        return result
    }
    
    func clickMenuItem(_ name: String) {
        let item = menuItem(name)
        item.click()
    }
    
    func menuItem(at path: [String]) -> XCUIElement {
        XCTAssertTrue(path.count > 0)
        let first = path.first!
        var result = application.menuBars.menuBarItems[first]
        if !result.exists {
            result = application.menuBars.menuItems[first]
        }
        
        for name in path.dropFirst() {
            result = result.menuItems[name]
        }
        return result
    }

    func clickMenuItem(at path: [String]) {
        let item = menuItem(at: path)
        item.click()
    }
    
    func toolbarButton(_ name: String, count: Int = 0) -> XCUIElement {
        let toolbar = scope.toolbars.element(boundBy: 0)
        let result = toolbar.children(matching: .button).matching(identifier: name).element(boundBy: count)
        return result
    }
    
    func clickToolbarButton(_ name: String, count: Int = 0) {
        let button = toolbarButton(name, count: count)
        button.click()
    }
    
    func button(_ name: String) -> XCUIElement {
        let result = scope.buttons[name]
        return result
    }
    
    func clickButton(_ name: String) {
        let button = self.button(name)
        button.click()
    }

    func field(_ name: String) -> XCUIElement {
        let result = scope.textFields[name]
        return result
    }
    
    func clickField(_ name: String) {
        let field = self.field(name)
        field.click()
    }

    func label(_ name: String) -> XCUIElement {
        let result = scope.staticTexts[name]
        return result
    }
    
    func clickLabel(_ name: String) {
        let label = self.label(name)
        label.click()
    }

    func table(_ name: String) -> XCUIElement {
        let result = scope.tables[name]
        return result
    }
    
    func tableRowCount(_ name: String) -> Int {
        return table(name).tableRows.count
    }
    
    func clickTableRow(_ row: Int, table: String) {
        let table = self.table(table)
        let row = table.tableRows.element(boundBy: row)
        row.click()
    }
    
    func tableRowValue(_ row: Int, table: String) -> String {
        let table = self.table(table)
        let row = table.tableRows.element(boundBy: row)
        let field = row.staticTexts.element(boundBy: 0)
        return field.value as! String
    }
    
    func with(scope: XCUIElement, block: () -> Void) {
        let oldScope = self.scope
        self.scope = scope
        block()
        self.scope = oldScope
    }
    
}
