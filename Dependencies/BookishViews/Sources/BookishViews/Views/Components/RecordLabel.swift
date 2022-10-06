// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 23/11/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

struct RecordLabel: View {
    enum NameMode {
        case normal
        case role(CDRecord)
        case roleInline(CDRecord)
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
            HStack {
                Spacer()
                if let url = record.imageURL {
                    LabelIconView(url: url, placeholder: record.iconName)
                } else {
                    Image(systemName: record.iconName)
                }
            }
            .frame(width: .labelIconWidth)
        }
    }
    
    var recordName: String {
        switch nameMode {
            case .roleInline(let role):
                return "\(record.name) (\(role.name))"
            default: return record.name
        }
    }

    var recordAnnotation: String? {
        switch nameMode {
            case .role(let role): return role.name
            default: return nil
        }
    }
}

extension CDRecord {
    var iconName: String {
        switch kind {
            case .root:
                switch id {
                    case .rootListsID: return "list.bullet.clipboard"
                    case .rootRolesID: return "person.crop.rectangle.stack"
                    default: return "books.vertical"
                }
                
            default:
                return kind.iconName
        }
    }
}

extension RecordKind {
    var iconName: String {
        switch self {
            case .unknown:          return "questionmark"
            case .book:             return "book"
            case .group:            return "folder"
            case .person:           return "person"
            case .role:             return "person.crop.rectangle"
            case .link:             return "link"
            case .publisher:        return "building.columns"
            case .importSession: 	return "square.and.arrow.down"
            case .series:           return "square.stack"
            case .root: 	        return "books.vertical"
            case .list:             return "books.vertical"
        }
    }
    
    var indexIconName: String {
        switch self {
            case .book: return "books.vertical"
            case .person: return "person.2"
            case .publisher: return "building.2"
            case .series: return "square.stack"
            default:
                return iconName
        }
    }
    
    var roleLabel: String {
        return "role.\(self)".localized
    }
    
    var pluralLabel: String {
        return "plural.\(self)".localized
    }
    
    var untitledLabel: String {
        return "untitled.\(self)"
    }
    
    var newLabel: String {
        return "new.\(self)"
    }

    var allItemsTag: String {
        return "all-\(self)"
    }
}
