// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 23/11/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

struct RecordLabel: View {
    enum NameMode {
        case normal
        case role(String)
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
                let localizedRole = "role.\(role)".localized
                return "\(record.name) (\(localizedRole))"
            default: return record.name
        }
    }

    var recordAnnotation: String? {
        switch nameMode {
            case .role(let role): return "role.\(role)".localized
            default: return nil
        }
    }
}

extension CDRecord {
    var iconName: String {
        switch kind {
            case .root:
                if let rootList = ModelController.RootList(rawValue: id) {
                    switch rootList {
                        case .imports:       return "display.and.arrow.down"
                        case .people:        return "person.2"
                        case .publishers:    return "building.2"
                        default:             break
                    }
                }
                
            default:
                return kind.iconName
        }
        
        return "books.vertical"
    }
}
extension CDRecord.Kind {
    var iconName: String {
        switch self {
            case .unknown:          return "questionmark"
            case .book:             return "book"
            case .group:            return "folder"
            case .person:           return "person"
            case .role:             return "person.text.rectangle"
            case .roleList:         return "list.bullet"
            case .publisher:        return "building.columns"
            case .importSession: 	return "square.and.arrow.down"
            case .series:           return "books.vertical"
            case .root: 	        return "books.vertical"
            case .list:             return "books.vertical"
            case .entry:             return "list.bullet.rectangle"
        }
    }
    
    var defaultRole: String {
        return "\(self)"
    }
    
    var untitledLabel: String {
        return "untitled.\(self)"
    }
    
    var newLabel: String {
        return "new.\(self)"
    }
}
