// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 08/12/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI
import ThreadExtensions

public class StatusController: ObservableObject {
    @Published var status: String?
    @Published var errors: [Error]
    
    public init() {
        errors = []
    }
    
    func notify(_ error: Error) {
        onMainQueue { [self] in
            errors.append(error)
        }
    }
}
