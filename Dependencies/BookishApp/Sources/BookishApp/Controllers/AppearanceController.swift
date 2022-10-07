// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 08/12/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

public class AppearanceController: ObservableObject {
    
    public init() {
    }
    
    func formatted(date: Date) -> String {
        let formatted = DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .none)
        return formatted
    }
}
