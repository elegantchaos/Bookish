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
                if let (text, icon, layout) = textAndIcon(for: field) {
                    PropertyView(label: field.key, icon: icon, value: text, layout: layout)
                }
            }
        }
    }
        
    func textAndIcon(for field: Field) -> (String, String, PropertyView.Layout)? {
        switch field.kind {
            case .string:
                if let string = record.string(forKey: field.key), !string.isEmpty {
                    return (string, "tag", .inline)
                }

            case .paragraph:
                if let string = record.string(forKey: field.key), !string.isEmpty {
                    return (string, "note.text", .below)
                }

            case .date:
                if let date = record.date(forKey: field.key) {
                    let string = appearance.formatted(date: date)
                    return (string, "calendar", .inline)
                }
                
            case .number:
                if let string = record.string(forKey: field.key), !string.isEmpty {
                    return (string, "tag", .inline)
                }
        }
        
        return nil
    }
}
