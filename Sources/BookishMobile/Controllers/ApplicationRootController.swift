// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 24/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit
import BookishModel

class ApplicationRootController: UISplitViewController {
    var showIntro = IntroController.shouldShow

    override func viewDidAppear(_ animated: Bool) {
        if showIntro {
            performSegue(withIdentifier: "intro", sender: self)
            showIntro = false
        }
        
        super.viewDidAppear(animated)
    }
}
