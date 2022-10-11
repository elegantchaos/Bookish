// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/10/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

struct LinkSessionHost<Content>: View where Content: View {
    @EnvironmentObject var linkController: LinkController

    let delegate: AddLinkDelegate
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        if let session = linkController.session {
            AddLinkView(kind: session.kind, delegate: delegate)
                .onDisappear(perform: handleDisappear)
                .toolbar {
                    ToolbarItem {
                        Button(action: { linkController.session = nil} ) {
                            Text("Cancel")
                        }
                    }
                }
        } else {
            content()
        }
    }
    
    func handleDisappear() {
        if linkController.session != nil {
            print("link session was cancelled by view getting hidden")
            linkController.session = nil
        }
    }
}
