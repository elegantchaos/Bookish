// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 23/11/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

struct RecordLabel: View {
    enum NameMode {
        case normal
        case role(String)
        case roleInline(String)
    }
    
    @ObservedObject var record: CDRecord
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
                    Spacer()
                    Text(annotation)
                        .foregroundColor(.secondary)
                        .font(.footnote)
                }
            }
        } icon: {
            if let url = record.imageURL {
                LabelIconView(url: url, placeholder: record.kind.iconName)
            } else {
                Image(systemName: record.kind.iconName)
                    .frame(minWidth: 20.0)
            }
        }
    }
    
    var recordName: String {
        switch nameMode {
            case .roleInline(let role): return "\(record.name) (\(role))"
            default: return record.name
        }
    }

    var recordAnnotation: String? {
        switch nameMode {
            case .role(let role): return role
            default: return nil
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
            case .person:
                return "Person"
                
            case .publisher:
                return "Publisher"

            case .series:
                return "Series"
                
            case .importSession:
                return "From"

            default:
                return "\(self)"
        }
    }
}
