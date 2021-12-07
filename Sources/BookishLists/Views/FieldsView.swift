// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 01/12/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

struct FieldsView: View {
    @EnvironmentObject var appearance: AppearanceController
    
    let record: CDRecord
    let fields: FieldList
    
    var body: some View {
        VStack(spacing: 8.0) {
            ForEach(fields.fields) { field in
                if let text = text(for: field), !text.isEmpty {
                    PropertyView(label: field.label, icon: field.icon, value: text, layout: field.layout)
                }
            }
        }
    }
        
    func text(for field: Field) -> String? {
        switch field.kind {
            case .date:
                if let date = record.date(forKey: field.key) {
                    let string = appearance.formatted(date: date)
                    return string
                }

            default:
                return record.string(forKey: field.key)
        }
        
        return nil
    }
}
