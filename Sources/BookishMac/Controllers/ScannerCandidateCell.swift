// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 28/02/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import BookishModel

class ScannerCandidateCell: NSTableCellView {
    
    static var dateFormatter: DateFormatter = makeDateFormatter()

    @IBOutlet weak var coverView: NSImageView!
    @IBOutlet weak var titleField: NSTextField!
    @IBOutlet weak var authorsField: NSTextField!
    @IBOutlet weak var publisherField: NSTextField!
    
    class func makeDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter
    }
    
    func setup(with candidate: LookupCandidate) {
        titleField.stringValue = candidate.title
        authorsField.stringValue = candidate.authors.joined(separator: ", ")
        
        var publisher = candidate.publisher
        
        if let date = candidate.date {
            let year = ScannerCandidateCell.dateFormatter.string(from: date)
            if !publisher.isEmpty {
                publisher += ", "
            }
            publisher += year
        }

        publisherField.stringValue = publisher
        
        if let urlString = candidate.image, let url = URL(string: urlString) {
            application.imageCache.image(for: url) { (image) in
                self.coverView.image = image
            }
        }

    }
}
