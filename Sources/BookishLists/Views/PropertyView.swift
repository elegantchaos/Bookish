// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/12/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

struct PropertyView: View {
    let label: String
    let icon: String
    let value: String
    let layout: Field.Layout

    var body: some View {
        VStack {
            switch layout {
                case .inline:
                    HStack {
                        Label(label, systemImage: icon)
                        Spacer()
                        Text(value)
                    }

                case .below:
                    HStack {
                        Label(label, systemImage: icon)
                        Spacer()
                    }
                    .padding(.top)
                    
                    HStack {
                        Text(value)
                        Spacer()
                    }
                    .padding(.bottom)

                case .belowNoLabel:
                    HStack {
                        Text(value)
                        Spacer()
                    }
                    .padding(.bottom)
            }
        }
    }
}
