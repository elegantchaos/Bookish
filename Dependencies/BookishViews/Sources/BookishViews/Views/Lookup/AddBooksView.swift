// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 09/03/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CaptureView
import SheetController
import SwiftUI
import SwiftUIExtensions

struct AddBooksView: View {
    enum Mode: String {
        case scan
        case search

        var label: String {
            return "add.\(rawValue)".localized
        }
        
        var help: String {
            return "add.\(rawValue).help".localized
        }

        var iconName: String {
            switch self {
                case .scan: return "barcode.viewfinder"
                case .search: return "magnifyingglass.circle"
            }
        }
    }
    
    let mode: Mode
    
    @EnvironmentObject var lookup: LookupManager
    @State var barcode: String = ""
    @State var session: LookupSession? = nil
    @State var candidates: [LookupCandidate] = []
    @State var search: String = ""
    @State var searching = false
    @State var selection: UUID?
    
    var body: some View {
        NavigationView {
            VStack {
                if mode == .scan {
                    CaptureView { scanned in
                        if scanned != barcode {
                            barcode = scanned
                            session?.cancel()
                            session = lookup.lookup(query: scanned) { session, state in
                                handleLookupProgress(session: session, state: state)
                            }
                        }
                    }
                    .aspectRatio(1.0, contentMode: .fit)
                } else {
                    HStack {
                        SearchBar(value: $search, placeholder: "Enter EAN, ISBN, title, author, etc", action: handleSearchChanged)
                        
                        if !search.isEmpty && session?.search != search {
                            Button(action: handleLookup) {
                                Text("Find")
                            }
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
                        CandidatesView(candidates: candidates, selection: $selection)
                    }
                } else {
                    Text(mode.help)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding()
                }

                if !searching || !gotCandidates {
                    Spacer()
                }
                

            }
            .navigationBarItems(
                trailing: SheetDismissButton()
            )
            .navigationTitle(mode.label)
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
        .onAppear(perform: handleAppeared)
    }
    
    func handleAppeared() {
        #if DEBUG
        if mode == .search {
            search = "phlebas"
            handleLookup()
        }
        #endif
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
