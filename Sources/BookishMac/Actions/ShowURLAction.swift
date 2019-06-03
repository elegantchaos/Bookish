// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 03/06/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Actions
import AppKit

class ShowURLAction: Action {
    let url: URL
    
    init(url: URL, identifier: String?) {
        self.url = url
        super.init(identifier: identifier)
    }
    
    init(plistKey: String, identifier: String) {
        if let info = Bundle.main.infoDictionary, let string = info[plistKey] as? String, let url = URL(string: string) {
                self.url = url
        } else {
            self.url = URL(string:"missing key \(plistKey)")!
        }
        
        super.init(identifier: identifier)
    }
    
    override func perform(context: ActionContext) {
        NSWorkspace.shared.open(url)
    }
}
