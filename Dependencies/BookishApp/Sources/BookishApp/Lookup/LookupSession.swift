// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 27/02/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
//import Datastore

class LookupSession {
    enum State {
        case starting
        case foundCandidate(LookupCandidate)
        case failed(LookupService)
        case cancelling
        case done
    }
    
    typealias Callback = (LookupSession, State) -> Void
    
    let search: String
    let manager: LookupManager
    var callback: Callback?
    var running: Set<LookupService>
    
    init(search: String, manager: LookupManager, callback: @escaping Callback) {
        self.search = search
        self.manager = manager
        self.callback = callback
        self.running = Set<LookupService>()
    }
    
    func run() {
        let services = manager.services
        let search = self.search
        let workerQueue = manager.workerQueue

        manager.lockQueue.async {
            self.callback(state: .starting)
            if services.count > 0 {
                for service in services {
                    self.running.insert(service)
                    workerQueue.async {
                        service.lookup(search: search, session: self)
                    }
                }
            } else {
                self.callback(state: .done)
            }
        }
    }
    
    func cancel() {
        manager.lockQueue.async {
            self.callback(state: .cancelling)
            self.callback = nil
            for service in self.running {
                service.cancel()
            }
            self.running.removeAll()
        }
    }
    
    func callback(state: State) {
        manager.callbackQueue.async {
            self.callback?(self, state)
        }
    }
    
    func add(candidate: LookupCandidate) {
        lookupChannel.log("Candidate \(candidate)")
        self.callback(state: .foundCandidate(candidate))
    }
    
    func done(service: LookupService) {
        manager.lockQueue.async {
            if let _ = self.running.remove(service) {
                if self.running.count == 0 {
                    self.callback(state: .done)
                }
            }
        }
    }

    func failed(service: LookupService) {
        manager.lockQueue.async {
            if let _ = self.running.remove(service) {
                self.callback(state: .failed(service))
                if self.running.count == 0 {
                    self.callback(state: .done)
                }
            }
        }
    }
    
}

