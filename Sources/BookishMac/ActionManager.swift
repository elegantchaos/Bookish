// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/09/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import BookishModel

class Action {
    let identifier: String
    
    func perform(context: ActionContext) {
        print("generic action \(context)")
    }
    
    init(identifier: String) {
        self.identifier = identifier
    }
}

class TestAction: Action {
    override func perform(context: ActionContext) {
        print("test parameter was \(context.info["Test"]!)")
    }
}

class InsertPersonAction: Action {
    override func perform(context: ActionContext) {
        if context.components.count > 1 {
            let roleName = context.components[1]
            //        if let selection = context.info["Selection"] as? [Book] {
            //            // update model
            //            let context = context.info["MOC"] as? NSManagedObjectContext
            //            let person = Person(context: context)
            //            let role = person.role(as: roleName)
            //            for book in selection {
            //                book.addToPersonRoles(role)
            //            }
            //
            //            // update table
            //            let count = people.count
            //            people.append(role)
            //            detailsView.insertRows(at: IndexSet(integer: count), withAnimation: .slideDown)
            //        }
        }
    }
}

@objc class ActionContext: NSObject {
    typealias ActionComponents = [String]
    
    let target: NSResponder
    let sender: Any
    var components = ActionComponents()
    var info = [String:Any]()
    
    init(target: NSResponder, sender: Any) {
        self.target = target
        self.sender = sender
    }
}

protocol ActionContextProvider {
    func provide(context: ActionContext)
}

class ActionManager {
    var actions = [String:Action]()
    
    init() {
        
    }
    
    func register(action: Action) {
        actions[action.identifier] = action
    }

    func gather(context: ActionContext) {
        let app = NSApplication.shared
        let keyWindow = app.keyWindow
        gather(context: context, from: keyWindow?.firstResponder)
        let mainWindow = app.mainWindow
        if keyWindow != mainWindow {
            gather(context: context, from: mainWindow?.firstResponder)
        }
        if let appProvider = app.delegate as? ActionContextProvider {
            appProvider.provide(context: context)
        }
    }

    func gather(context: ActionContext, from: NSResponder?) {
        var responder = from
        while (responder != nil) {
            if let provider = responder as? ActionContextProvider {
                provider.provide(context: context)
            }
            responder = responder?.nextResponder
        }
    }

    func perform(action: String, context: ActionContext) {
        let components = action.split(separator: ".").map { String($0) }
        let actionID = components[0]
        if let action = actions[actionID] {
            context.components = components
            gather(context: context)
            action.perform(context: context)
        }
    }
    
}
