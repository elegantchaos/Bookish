// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 07/12/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

struct ActionsMenuButton<MenuContent>: View where MenuContent: View {
    let content: () -> MenuContent
    
    var body: some View {
        Menu() {
            content()
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
}
