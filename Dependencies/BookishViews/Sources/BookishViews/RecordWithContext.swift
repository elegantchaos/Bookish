// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/10/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Link to a record, along with another optional record
/// which represents the context. Usually this will be a list
/// containing the record, that we navigated to it from.
public struct RecordWithContext: Hashable {
    let record: CDRecord
    let context: CDRecord?
}
