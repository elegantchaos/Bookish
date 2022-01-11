// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/01/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

protocol RecordContainerView {
    var container: CDRecord { get }
    func dismiss()
}

struct RecordContainerKey: EnvironmentKey {
    static let defaultValue: RecordContainerView? = nil
}

extension EnvironmentValues {
    var recordContainer: RecordContainerView? {
        get { self[RecordContainerKey.self] }
        set { self[RecordContainerKey.self] = newValue }
    }
}
