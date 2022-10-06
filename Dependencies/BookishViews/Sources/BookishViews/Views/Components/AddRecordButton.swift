// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 15/12/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

struct AddRecordButton: View {
    @EnvironmentObject var model: ModelController
    let container: CDRecord?
    let kind: RecordKind
    @Binding var selection: String?
    
    var body: some View {
        Button(action: handleAddRecord) {
            Label(kind.newLabel, systemImage: kind.iconName)
        }
    }

    func handleAddRecord() {
        let record : CDRecord = model.add(kind)
        if let container = container {
            container.addToContents(record)
        }
        record.name = kind.untitledLabel
        selection = record.id
    }
}
