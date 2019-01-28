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

protocol HasValidatableActions {
    func validateButtons()
    func scheduleForValidation()
}

extension HasValidatableActions {
    func scheduleForValidation() {
        OperationQueue.main.addOperation {
            self.validateButtons()
        }
    }
}

extension ActionManagerMobile {
    func validate(items: [ActionIdentification]) {
        for item in items {
            let identifier = item.actionID
            if !identifier.isEmpty {
                let validation = validate(identifier: item.actionID, info: ActionInfo(sender: item))
                if let button = item as? UIButton {
                    button.isEnabled = validation.enabled
                    button.isHidden = !validation.visible
                    if let name = validation.name {
                        button.setTitle(name, for: .normal)
                    }
                } else if let item = item as? UIBarItem {
                    item.isEnabled = validation.enabled
                    if let name = validation.name {
                        item.title = name
                    }
                }
            }
        }
    }
}

extension UIViewController: HasValidatableActions {
    func validateButtons() {
        let actionManager = Application.sharedInstance.actionManager
        var items = [ActionIdentification]()
        view.appendValidatableItems(to: &items)
        navigationController?.appendValidatableItems(to: &items)
        actionManager.validate(items: items)
    }
}

extension UINavigationController {
    func appendValidatableItems(to items: inout [ActionIdentification]) {
        if let leftButtons = navigationBar.topItem?.leftBarButtonItems {
            items.append(contentsOf: leftButtons)
        }
        if let rightButtons = navigationBar.topItem?.rightBarButtonItems {
            items.append(contentsOf: rightButtons)
        }
    }
}

extension UIView: HasValidatableActions {
    func appendValidatableItems(to items: inout [ActionIdentification]) {
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
        var items = [ActionIdentification]()
        appendValidatableItems(to: &items)
        actionManager.validate(items: items)
    }
    }
