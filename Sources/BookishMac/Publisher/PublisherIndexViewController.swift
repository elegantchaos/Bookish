// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 03/12/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import BookishModel
import Actions

class PublisherIndexViewController: IndexController<Publisher>, PublisherLifecycleObserver {
    func created(publisher: Publisher) {
        indexArray.setSelectedObjects([publisher])
    }
    
    func deleted(publisher: Publisher) {
    }
}
