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
    
    @IBOutlet weak var showDebugSwitch: UISwitch!

    override func viewWillAppear(_ animated: Bool) {
        showDebugSwitch.isOn = application.viewState.showDebug
    }
    
    @IBAction func resetToEmpty(_ sender: Any) {
        application.collectionController.reset(mode: .empty)
    }

    @IBAction func resetToTestData(_ sender: Any) {
        application.collectionController.reset(mode: .testData)
    }

    @IBAction func resetToSampleData(_ sender: Any) {
        application.collectionController.reset(mode: .sampleData)
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
