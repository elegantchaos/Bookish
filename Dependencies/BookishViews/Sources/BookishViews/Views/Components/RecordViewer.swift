// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/01/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

protocol RecordViewer {
    var record: CDRecord { get }
    func dismiss()
}

struct RecordViewerKey: EnvironmentKey {
    static let defaultValue: RecordViewer? = nil
}

extension EnvironmentValues {
    var recordViewer: RecordViewer? {
        get { self[RecordViewerKey.self] }
        set { self[RecordViewerKey.self] = newValue }
    }
}
