// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 09/03/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CaptureView
import SheetController
import SwiftUI

struct ScannerView: View {
    @EnvironmentObject var lookup: LookupManager
    @State var barcode: String = ""
    @State var session: LookupSession? = nil
    @State var candidates: [LookupCandidate] = []
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                CaptureView { scanned in
                    if scanned != barcode {
                        barcode = scanned
                        session?.cancel()
                        session = lookup.lookup(query: scanned) { session, state in
                            lookupUpdate(session: session, state: state)
                        }
                    }
                }

                if let session = session {
                    HStack {
                        ProgressView()
                        Text("looking up \(session.search)")
                    }
                }
                
                if candidates.count > 0 {
                    Text("Found \(candidates.count) candidates:")
                    ForEach(candidates, id: \.title) { candidate in
                        HStack {
                            Text(candidate.title)
                            Text(candidate.authors.joined(separator: ", "))
                        }
                    }
                }

                Spacer()
            }
            .navigationBarItems(
                trailing: SheetDismissButton()
            )
        }
    }
    
    func lookupUpdate(session: LookupSession, state: LookupSession.State) {
        switch state {
            case .starting:
                candidates = []
            
            case .done:
                self.session = nil
            
            case .foundCandidate(let candidate):
                candidates.append(candidate)

            default:
                break
        }
    }
}
