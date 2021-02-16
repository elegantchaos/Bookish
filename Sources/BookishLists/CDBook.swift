// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 26/01/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreData
import Images
import SwiftUI
import SwiftUIExtensions

class CDBook: NamedManagedObject {
}

extension CDBook {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDBook> {
        return NSFetchRequest<CDBook>(entityName: "CDBook")
    }

    @NSManaged public var lists: NSSet?
}

extension CDBook {

    @objc(addEntriesObject:)
    @NSManaged public func addToEntries(_ value: CDEntry)

    @objc(removeEntriesObject:)
    @NSManaged public func removeFromEntries(_ value: CDEntry)

    @objc(addEntries:)
    @NSManaged public func addToEntries(_ values: NSSet)

    @objc(removeEntries:)
    @NSManaged public func removeFromEntries(_ values: NSSet)

}

extension CDBook: AutoLinked {
    var linkView: some View {
        assert(isDeleted == false)
        return BookView(book: self)
    }
    
    var labelView: some View {
        assert(isDeleted == false)
        return ImageOwnerLabelView(object: self)
    }
}


struct ImageOwnerLabelView: View {
    @ObservedObject var object: NamedManagedObject
    
    var body: some View {
        Label {
            Text(object.name)
        } icon: {
            if let url = object.imageURL {
                LabelIconView(url: url, placeholder: "book")
            } else {
                Image(systemName: "book")
            }
        }
    }
}

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

struct LabelIconView: View {
    @EnvironmentObject var model: Model
    
    let url: URL
    let placeholder: String
    var body: some View {
        let image = model.images.image(for: url, default: placeholder)
        AsyncImageView(image)
            .frame(maxWidth: 32, maxHeight: 32)
    }
}
