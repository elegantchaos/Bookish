// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/12/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit
import CoreData

class SettingsController: UIViewController {
    
    @IBAction func resetToEmpty(_ sender: Any) {
        application.collectionController.reset(usingSample: false)
    }
    
    @IBAction func resetToSampleData(_ sender: Any) {
        application.collectionController.reset(usingSample: true)
    }
}
