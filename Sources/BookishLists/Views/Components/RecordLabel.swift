// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 23/11/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

struct RecordLabel: View {
    let record: CDRecord
    
    var body: some View {
        Label {
            Text(record.name)
        } icon: {
            if let url = record.imageURL {
                LabelIconView(url: url, placeholder: imageName)
            } else {
                Image(systemName: imageName)
            }
        }
    }
    
    var imageName: String {
        switch record.kind {
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
}
