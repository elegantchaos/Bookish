// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 15/09/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

struct LabelWithFixedWidthIcon: View {
    let label: String
    let systemImage: String

    init(_ label: String, systemImage: String) {
        self.label = label
        self.systemImage = systemImage
    }

    var body: some View {
        Label {
            Text(label)
        } icon: {
            HStack {
                Spacer()
                Image(systemName: systemImage)
            }
            .frame(width: .labelIconWidth)
        }
    }
}

extension CGFloat {
    static let labelIconWidth = 24.0
}
