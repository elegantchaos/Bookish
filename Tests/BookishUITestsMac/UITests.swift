// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/09/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import XCTest

class UITests: XCTestCase {
    let application = XCUIApplication()
    
    var menubar: XCUIElementQuery {
        return application.menuBars
    }
    
    func launch(arguments: [String] = []) {
        // launch with the --reset flag to ensure that we start in a known state
        application.launchArguments = ["-NSTreatUnknownArgumentsAsOpen", "NO", "-ApplePersistenceIgnoreState", "YES", "--ui-testing"]
        application.launchArguments.append(contentsOf: arguments)
        application.launch()
    }

    func menuItem(_ name: String) -> XCUIElement {
        return menubar.menuItems[name]
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
    
    func toolbarButton(_ name: String, count: Int = 0, window: String = "Untitled") -> XCUIElement {
        let window = application.windows[window]
        let toolbar = window.toolbars.element(boundBy: 0)
        return toolbar.children(matching: .button).matching(identifier: name).element(boundBy: count)
    }
    
    func button(_ name: String, window: String = "Untitled") -> XCUIElement {
        let window = application.windows[window]
        return window.buttons[name]
    }
}
