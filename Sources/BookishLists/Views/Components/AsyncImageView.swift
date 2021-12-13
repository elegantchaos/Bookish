// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 23/11/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Images
import SwiftUI

struct AsyncImageView: View {
    @ObservedObject var image: AsyncImage
    
    enum SizeMode {
        case natural                        /// Always use the image size
        case fixed(CGSize)                  /// Always use a fixed size
        case fixedUnlessEmpty(CGSize)       /// Use a fixed size if we have an image, but zero if the image is missing.
    }
    
    let sizeMode: SizeMode
    
    init(_ image: AsyncImage, sizeMode: SizeMode = .natural) {
        self.image = image
        self.sizeMode = sizeMode
    }
    
    var body: some View {
        let size = imageSize
        Image(uiImage: image.image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size.width, height: size.height)
    }
    
    var imageSize: CGSize {
        let naturalSize = image.image.size

        switch sizeMode {
            case .natural:
                return naturalSize
                
            case .fixed(let size):
                return size
                
            case .fixedUnlessEmpty(let size):
                return (naturalSize.width == 0) ? .zero : size
        }
    }
}
