// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/12/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit
import CoreData
import Logger
import LoggerKit

class SettingsController: UITableViewController {
    lazy var loggingSettings: LoggerSettingsView? = LoggerSettingsView()
    
    @IBOutlet weak var showDebugSwitch: UISwitch!
    @IBOutlet weak var aboutText: UITextView!
    
    override func viewWillAppear(_ animated: Bool) {
        showDebugSwitch.isOn = application.viewState.showDebug
        aboutText.text = "\(Bundle.main.fullName)\n\(Bundle.main.copyright)"
    }
    
    func confirm(title: String, message: String, completion: @escaping () -> Void) {
        let alert = UIAlertController(title: title.localized, message: message.localized, preferredStyle: .alert)
        alert.addAction(
            UIAlertAction(title: "reset.ok".localized, style: .destructive) { (UIAlertAction) in
                completion()
            }
        )
        
        alert.addAction(
            UIAlertAction(title: "reset.cancel".localized, style: .cancel)
        )
        
        self.present(alert, animated: true, completion: nil)

    }
    
    @IBAction func resetToEmpty(_ sender: Any) {
        let application = self.application
        confirm(title: "reset.empty.title", message: "reset.empty.message") {
            application.collectionController.reset(mode: .empty)
        }
    }

    @IBAction func resetToTestData(_ sender: Any) {
        let application = self.application
        confirm(title: "reset.test.title", message: "reset.test.message") {
            application.collectionController.reset(mode: .replaceWithTestData)
        }
    }

    @IBAction func resetToSampleData(_ sender: Any) {
        let application = self.application
        confirm(title: "reset.sample.title", message: "reset.sample.message") {
            application.collectionController.reset(mode: .replaceWithSampleData)
        }
    }
    
    @IBAction func showLoggingSettings(_ sender: Any) {
        if let button = sender as? UIButton {
            loggingSettings?.show(in: self, sender: button) {
            }
        }
    }
    
    @IBAction func toggleShowDebug(_ sender: Any) {
        application.viewState.showDebug = showDebugSwitch.isOn
    }
    
}
