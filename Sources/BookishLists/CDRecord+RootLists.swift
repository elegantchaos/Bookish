// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 23/11/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreData

// Root Lists

extension String {
    static let allImportsID = "all-imports"
    static let allPeopleID = "all-people"
    static let allPublishersID = "all-publishers"
    static let allSeriesID = "all-series"
}

extension NSManagedObjectContext {
    var allImports: CDRecord {
        return CDRecord.findOrMakeWithID(.allImportsID, in: self) { record in
            record.kind = .importIndex
            record.name = "Imports"
        }
    }

    var allPeople: CDRecord {
        return CDRecord.findOrMakeWithID(.allPeopleID, in: self) { created in
            created.kind = .personIndex
            created.name = "People"
        }
    }

    var allPublishers: CDRecord {
        return CDRecord.findOrMakeWithID(.allPublishersID, in: self) { created in
            created.kind = .publisherIndex
            created.name = "Publishers"
        }
    }

    var allSeries: CDRecord {
        return CDRecord.findOrMakeWithID(.allSeriesID, in: self) { created in
            created.kind = .seriesIndex
            created.name = "Series"
        }
    }

}
