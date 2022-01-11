// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/01/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

protocol RecordContainer {
    func handleRemove(record: CDRecord, as role: String)
    func handleRemoveLink(of record: CDRecord, as role: String)
}

struct RecordContainerKey: EnvironmentKey {
    static let defaultValue: CDRecord? = nil
}

extension EnvironmentValues {
    var recordContainer: CDRecord? {
        get { self[RecordContainerKey.self] }
        set { self[RecordContainerKey.self] = newValue }
    }
}
