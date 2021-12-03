// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 27/02/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

//import Datastore
import Foundation
import ISBN
import BookishCore

public class GoogleLookupCandidate: LookupCandidate {
    class func isbn(from info: [String:Any]) -> String? {
        if let identifiers = info["industryIdentifiers"] as? [[String:Any]] {
            for id in identifiers {
                if let type = id["type"] as? String, let value = id["identifier"] as? String {
                    switch type {
                    case "ISBN_13":
                        return value
                        
                    case "ISBN_10":
                        return value.isbn10to13
                        
                    default:
                        break
                    }
                }
            }
        }
        return nil
    }
    
    init(info: [String:Any], service: GoogleLookupService) {
        var updated = info

        if let publisher = updated.extractString(forKey: "publisher") {
            updated[.publishersKey] = [publisher]
        }

        if let string = updated.extractString(forKey: "publishedDate") {
            let matches = service.dateDetector.matches(in: string, options: NSRegularExpression.MatchingOptions(), range: NSRange(location: 0, length: string.count))
            let date: Date? = matches.first?.date
            updated[.publishedDateKey] = date
        }
        
        var image: String? = nil
        if let images = info["imageLinks"] as? [String:Any] {
            image = (images["thumbnail"] as? String) ?? (images["smallThumbnail"] as? String)
            image = image?.replacingOccurrences(of: "edge=curl&", with: "")
            image = image?.replacingOccurrences(of: "http://", with: "https://")
//            image = image?.replacingOccurrences(of: "zoom=1&", with: "")
        }
        
        if let image = image, let url = URL(string: image) {
            updated[.imageURLsKey] = [url]
        }

        updated[.isbnKey] = GoogleLookupCandidate.isbn(from: info)

        if let pages = info["pageCount"] as? NSNumber {
            updated[.pagesKey] = pages.intValue
        }

        let book = BookRecord(updated, id: UUID().uuidString, source: service.name)!
        super.init(service: service, record: book)
    }
 }

public class GoogleLookupService: LookupService {
    var fetcher: DataFetcher = JSONDataFetcher()
    let dateDetector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)

    public override func lookup(search: String, session: LookupSession) {
        let isISBN = search.isISBN10 || search.isISBN13
        let query = isISBN ? "q=isbn:\(search)" : "q=\(search.replacingOccurrences(of: " ", with: "+"))"
        var components = URLComponents(string: "https://www.googleapis.com/books/v1/volumes")
        components?.query = query
        guard
            let url = components?.url,
            let info = fetcher.info(for: url),
            let items = info["items"] as? [[String:Any]],
            items.count > 0
        else {
            session.failed(service: self)
            return
        }
        
        lookupChannel.log("Query \(query)")
        for item in items {
            if let volume = item["volumeInfo"] as? [String:Any] {
                let candidate = GoogleLookupCandidate(info: volume, service: self)
                session.add(candidate: candidate)
            }
        }

        session.done(service: self)
    }
    
    public override func restore(persisted: String) -> LookupCandidate? {
        guard let data = persisted.data(using: .utf8), let object = try? JSONSerialization.jsonObject(with: data, options: []), let info = object as? [String:Any] else { return nil }
        return GoogleLookupCandidate(info: info, service: self)
    }

}
