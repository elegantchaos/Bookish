// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/10/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

public class EditController: ObservableObject {
    @Published var isEditingFields = false
    
    public init() {
    }
    
    func startEditingFields() {
        isEditingFields = true
    }
    
    func stopEditingFields() {
        isEditingFields = false
    }
    
    func toggleEditingFields() {
        isEditingFields = !isEditingFields
    }
}
