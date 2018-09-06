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



class ActionContext: NSObject {
    static let SelectionKey = "selection"
    static let TargetKey = "target"
    static let SenderKey = "sender"
    static let ModelObjectContextKey = "moc"
    static let ActionKey = "action"
    static let ActionComponentsKey = "components"

    let sender: Any
    var parameters: [String]
    var info = [String:Any]()

    init(sender: Any, parameters: [String]) {
        self.sender = sender
        self.parameters = parameters
    }
}

protocol ActionContextProvider {
    func provide(context: ActionContext)
}

@objc class ActionManager: NSResponder {
    var actions = [String:Action]()
    
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

    func perform(_ sender: Any) {
    }

    @IBAction func performAction(_ sender: Any) {
        if let identifier = (sender as? NSUserInterfaceItemIdentification)?.identifier?.rawValue {
            let components = identifier.split(separator: ".")
            let actionID = String(components[0])
            let parameters = components.dropFirst().map { String($0) }
            if let action = actions[actionID] {
                let context = ActionContext(sender: sender, parameters: parameters)
                gather(context: context)
                action.perform(context: context)
            }
        }
    }
    
}
