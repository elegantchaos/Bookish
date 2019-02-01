// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 31/01/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit

extension UIButton {
    func setTitle(_ string: String?, font: UIFont, for state: UIButton.State = .normal) {
        let title = NSAttributedString(string: string ?? "", attributes: [NSAttributedString.Key.font: font])
        setAttributedTitle(title, for: state)
    }
}
