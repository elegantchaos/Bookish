// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 23/11/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Images
import SwiftUI

struct AsyncImageView: View {
    @ObservedObject var image: AsyncImage
    
    init(_ image: AsyncImage) {
        self.image = image
    }
    
    var body: some View {
        Image(uiImage: image.image)
            .resizable()
            .aspectRatio(contentMode: .fit)
    }
}
