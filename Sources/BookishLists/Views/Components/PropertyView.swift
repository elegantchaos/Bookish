// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/12/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

struct PropertyView<Content>: View where Content: View {
    let label: String
    let icon: String
    let content: () -> Content
    let layout: Field.Layout

    init(label: String, icon: String, layout: Field.Layout, @ViewBuilder content: @escaping () -> Content) {
        self.label = label
        self.icon = icon
        self.content = content
        self.layout = layout
    }

    init(label: String, icon: String, value: String, layout: Field.Layout) where Content == Text {
        self.init(label: label, icon: icon, layout: layout, content: {
            Text(value)
        })
    }

    var body: some View {
        VStack {
            switch layout {
                case .inline:
                    HStack {
                        Label(label, systemImage: icon)
                        Spacer()
                        content()
                    }

                case .below:
                    HStack {
                        Label(label, systemImage: icon)
                        Spacer()
                    }
                    .padding(.top)
                    
                    HStack {
                        content()
                        Spacer()
                    }
                    .padding(.bottom)

                case .belowNoLabel:
                    HStack {
                        content()
                        Spacer()
                    }
                    .padding(.bottom)
            }
        }
    }

}
