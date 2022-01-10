// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 10/01/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import ISBN
import BookishCore
import CoreData

public class SelfLookupService: LookupService {
    let model: ModelController

    init(name: String, model: ModelController) {
        self.model = model
        super.init(name: name)
    }
    
    public override func lookup(search: String, session: LookupSession) {
        model.stack.onBackground { context in
            let request: NSFetchRequest<CDRecord> = CDRecord.fetcher(in: context)
            request.predicate = NSPredicate(format: "name CONTAINS[cd] %@", search)
            if let records = try? context.fetch(request) {
                for result in records {
                    if result.kind == .book, let book = result.asBookRecord(from: self.name)  {
                        let candidate = LookupCandidate(service: self, record: book)
                        session.add(candidate: candidate)
                    }
                }
            }
            session.done(service: self)
        }
    }
    
//    public override func restore(persisted: String) -> LookupCandidate? {
////        guard let data = persisted.data(using: .utf8), let object = try? JSONSerialization.jsonObject(with: data, options: []), let info = object as? [String:Any] else { return nil }
////        return SelfLookupCandidate(info: info, service: self)
//    }

}
