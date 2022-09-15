// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 26/01/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Images
import SwiftUI
import SwiftUIExtensions

struct LabelIconView: View {
    @EnvironmentObject var model: ModelController
    
    let url: URL
    let placeholder: String
    var body: some View {
        let image = model.images.image(for: url, default: placeholder)
        AsyncImageView(image, sizeMode: .fixed(.init(width: 32, height: 32)))
    }
}
