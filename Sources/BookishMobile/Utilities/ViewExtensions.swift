// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit
import Actions
import ActionsKit
import Logger

let validationChannel = Logger("Validation")

extension UIResponder {
    /**
     Convenience to return the application delegate singleton.
     */
    
    var application: Application {
        return UIApplication.shared.delegate as! Application
    }
        

}

extension UIView {
    func appendValidatableItems(to items: inout [UIControl]) {
        let selector = ActionManagerMobile.Responder.performActionSelector
        if !isHidden {
            if let viewItem = self as? UIControl, !viewItem.actionID.isEmpty {
                validationChannel.log("\(viewItem.actionID)")
                items.append(viewItem)
            }
            for subview in subviews {
                subview.appendValidatableItems(to: &items)
            }
        }
    }
    
    func validateButtons() {
        let actionManager = Application.sharedInstance.actionManager
        var items = [UIControl]()
        appendValidatableItems(to: &items)
        for item in items {
            if let button = item as? UIButton, !button.actionID.isEmpty {
                let validation = actionManager.validate(identifier: button.actionID, info: ActionInfo(sender: button))
                button.isEnabled = validation.enabled
                button.isHidden = !validation.visible
                if let name = validation.name {
                    button.setTitle(name, for: .normal)
                }
            }
        }
    }
    
    func scheduleForValidation() {
        OperationQueue.main.addOperation {
            self.validateButtons()
        }
    }
}
