// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/01/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

struct RawPropertiesSection: View
{
    @AppStorage("showRaw") var showRaw = false
    @AppStorage("enableRawProperties") var enableRawProperties = false
    
    let record: CDRecord
    
    var body: some View {
        if enableRawProperties {
            Section {
                if showRaw {
                    RawPropertiesView(record: record)
                }
            } header: {
                DisclosureGroup("Raw Properties", isExpanded: $showRaw) {
                }
            }
        }
    }
}

struct RawPropertiesGroup: View {
    @AppStorage("showRaw") var showRaw = false
    @AppStorage("enableRawProperties") var enableRawProperties = false
    
    let record: CDRecord
    
    var body: some View {
        if enableRawProperties {
            DisclosureGroup("Raw Properties", isExpanded: $showRaw) {
                RawPropertiesView(record: record)
            }
        }
    }
}

struct RawPropertiesView: View {
    let record: CDRecord
    
    var body: some View {
        LazyVStack(alignment: .leading, spacing: 8.0) {
            let keys = record.sortedKeys
            ForEach(keys, id: \.self) { key in
                if let value = record.property(forKey: key) {
                    RawPropertyView(key: key, value: value)
                        .padding(.bottom)
                }
            }
        }
        
    }
}
