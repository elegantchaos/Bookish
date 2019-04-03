// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 03/04/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit

class IntroController: UIViewController {
    
    @IBOutlet weak var disclaimerText: UITextView!
    @IBOutlet weak var showAlwaysSwitch: UISwitch!
    
    static let LastShownKey = "introLastShown"
    static let OncePerVersionKey = "introOncePerVersion"
    
    class var shouldShow: Bool {
        let showOnce = UserDefaults.standard.bool(forKey: IntroController.OncePerVersionKey)
        let lastShownVersion = UserDefaults.standard.string(forKey: IntroController.LastShownKey)
        let version = Bundle.main.buildString
        return !showOnce || (version != lastShownVersion)
    }

    override func viewWillAppear(_ animated: Bool) {
        if let url = Bundle.main.url(forResource: "Introduction", withExtension: ".rtf"), let text = try? NSAttributedString(url: url, options: [:], documentAttributes: nil) {
            disclaimerText.attributedText = text
        }
        
        showAlwaysSwitch.isOn = !UserDefaults.standard.bool(forKey: IntroController.OncePerVersionKey)
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        UserDefaults.standard.set(Bundle.main.buildString, forKey: IntroController.LastShownKey)
        super.viewDidAppear(animated)
    }
    
    @IBAction func dismissAction(_ sender: Any) {
        UserDefaults.standard.set(!showAlwaysSwitch.isOn, forKey: IntroController.OncePerVersionKey)
        self.dismiss(animated: true)
    }
}
