// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 23/11/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

struct RecordLabel: View {
    enum NameMode {
        case normal
        case includeRole
    }
    
    let record: CDRecord
    let nameMode: NameMode

    init(record: CDRecord, nameMode: NameMode = .normal) {
        self.record = record
        self.nameMode = nameMode
    }
    
    var body: some View {
        Label {
            HStack {
                Text(recordName)
                if let annotation = recordAnnotation {
                    Text("(\(annotation))")
                        .foregroundColor(.secondary)
                }
            }
        } icon: {
            if let url = record.imageURL {
                LabelIconView(url: url, placeholder: record.kind.iconName)
            } else {
                Image(systemName: record.kind.iconName)
            }
        }
    }
    
    var recordName: String {
        if nameMode == .includeRole, record.kind == .personRole, let person = record.containedBy?.first {
            return person.name
        } else {
            return record.name
        }
    }
    
    var recordAnnotation: String? {
        guard nameMode == .includeRole else { return nil }
        if record.kind == .personRole {
            return record.name
        } else {
            return record.kind.roleLabel
        }
    }
}

extension CDRecord.Kind {
    var iconName: String {
        switch self {
            case .book: return "book"
            case .group: return "folder"
            case .person: return "person"
            case .personIndex: return "person.2"
            case .personRole: return "person.text.rectangle"
            case .publisherIndex: return "building.2"
            case .publisher: return "building.columns"
            case .importIndex: return "display.and.arrow.down"
            case .importSession: return "square.and.arrow.down"
                
            default:
                return "books.vertical"
        }
    }
    
    var roleLabel: String {
        switch self {
            case .publisher:
                return "Publisher"

            case .series:
                return "Series"
                
            case .importSession:
                return "Imported"

            default:
                return "\(self)"
        }
    }
}
