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
        VStack(spacing: 4.0) {
            ForEach(fields.fields) { field in
                if let (text, icon) = textAndIcon(for: field) {
                    PropertyView(label: field.key, icon: icon, value: text)
                }
            }
        }
    }
        
    func textAndIcon(for field: Field) -> (String, String)? {
        switch field.kind {
            case .string:
                if let string = record.string(forKey: field.key), !string.isEmpty {
                    return (string, "tag")
                }
                
            case .date:
                if let date = record.date(forKey: field.key) {
                    let string = appearance.formatted(date: date)
                    return (string, "calendar")
                }
                
            case .number:
                if let string = record.string(forKey: field.key), !string.isEmpty {
                    return (string, "tag")
                }
        }
        
        return nil
    }
}

struct PropertyView: View {
    let label: String
    let icon: String
    let value: String

    var body: some View {
        HStack {
            Label(label, systemImage: icon)
            Spacer()
            Text(value)
        }
    }
}
