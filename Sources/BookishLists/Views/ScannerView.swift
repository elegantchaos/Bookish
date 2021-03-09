// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 09/03/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CaptureView
import SheetController
import SwiftUI
import SwiftUIExtensions

struct ScannerView: View {
    @EnvironmentObject var lookup: LookupManager
    @State var barcode: String = ""
    @State var session: LookupSession? = nil
    @State var candidates: [LookupCandidate] = []
    @State var search: String = ""
    @State var searching = false
    @State var selection: LookupCandidate?
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    SearchBar(value: $search, placeholder: "Enter EAN, ISBN, title, author, etc", action: handleSearchChanged)
                    
                    if !search.isEmpty && session?.search != search {
                        Button(action: handleLookup) {
                            Text("Find")
                                .padding()
                        }
                    }
                }
                
                let gotCandidates = candidates.count > 0
                if searching || gotCandidates {
                    HStack {
                        Text(gotCandidates ? "Found \(candidates.count) candidates:" : "Searching…")
                        if searching {
                            ProgressView()
                        }
                    }
                    
                    if gotCandidates {
                        ForEach(candidates, id: \.title) { candidate in
                            LinkView(candidate, selection: $selection)
//                            CandidateView(candidate: candidate)
                        }
                    }
                }
                
                CaptureView { scanned in
                    if scanned != barcode {
                        barcode = scanned
                        session?.cancel()
                        session = lookup.lookup(query: scanned) { session, state in
                            handleLookupProgress(session: session, state: state)
                        }
                    }
                }
            }
            .navigationBarItems(
                trailing: SheetDismissButton()
            )
        }
    }
    
    func handleLookup() {
        lookup(value: search)
    }
    
    func handleSearchChanged(_ value: String) {
        if value.isEmpty {
            session?.cancel()
            candidates = []
        } else {
            lookup(value: value)
        }
    }
    
    func lookup(value: String) {
        if value != session?.search {
            search = value
            session?.cancel()
            session = lookup.lookup(query: value) { session, state in
                handleLookupProgress(session: session, state: state)
            }
        }
    }
    
    func handleLookupProgress(session: LookupSession, state: LookupSession.State) {
        switch state {
            case .starting:
                searching = true
                candidates = []
                
            case .done:
                searching = false
                
            case .foundCandidate(let candidate):
                candidates.append(candidate)
                
            default:
                break
        }
    }
}
