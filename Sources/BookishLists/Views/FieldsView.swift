// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 01/12/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

struct FieldsView: View {
    let record: CDRecord
    let fields: FieldList
    
    var body: some View {
        VStack(spacing: 4.0) {
            ForEach(fields.fields) { field in
                switch field.kind {
                    case .string:
                        if let string = record.string(forKey: field.key), !string.isEmpty {
                            HStack {
                                Label(field.key, systemImage: "tag")
                                Spacer()
                                Text(string)
                            }
                        }

                    case .date:
                        if let date = record.date(forKey: field.key) {
                            HStack {
                                Label(field.key, systemImage: "calendar")
                                Spacer()
                                Text(DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none))
                            }
                        }

                    case .number:
                        if let string = record.string(forKey: field.key), !string.isEmpty {
                            HStack {
                                Label(field.key, systemImage: "tag")
                                Spacer()
                                Text(string)
                            }
                        }

                }
            }
        }
    }
}
