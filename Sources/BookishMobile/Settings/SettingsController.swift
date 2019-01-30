// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/12/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit
import CoreData
import Logger
import LoggerKit

class SettingsController: UIViewController {
    lazy var loggingSettings: LoggerSettingsView? = LoggerSettingsView()
    
    @IBAction func resetToEmpty(_ sender: Any) {
        application.collectionController.reset(usingSample: false)
    }
    
    @IBAction func resetToSampleData(_ sender: Any) {
        application.collectionController.reset(usingSample: true)
    }
    
    @IBAction func showLoggingSettings(_ sender: Any) {
        if let button = sender as? UIButton {
            loggingSettings?.show(in: self, sender: button) {
            }
        }
    }
}
