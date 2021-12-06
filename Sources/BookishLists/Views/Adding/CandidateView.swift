// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 09/03/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI
import SwiftUIExtensions

extension LookupCandidate: AutoLinked {
    public var linkView: some View {
        return CandidateDetailView(candidate: self)
    }
    
    public var labelView: some View {
        return CandidateLabelView(candidate: self)
    }
}

struct CandidateLabelView: View {
    @ObservedObject var candidate: LookupCandidate
    
    var body: some View {
        HStack {
            ZStack(alignment: .bottomTrailing) {
                if let url = candidate.image {
                    LabelIconView(url: url, placeholder: "book")
                } else {
                    Image(systemName: "book")
                }
                
                if candidate.imported {
                    Image(systemName: "checkmark")
                        .font(.footnote)
                        .foregroundStyle(.primary, .tint, .background)
                        .symbolRenderingMode(.palette)
                        .symbolVariant(.circle)
                        .symbolVariant(.fill)

                    Image(systemName: "checkmark")
                        .font(.footnote)
                        .symbolRenderingMode(.monochrome)
                        .symbolVariant(.circle)

                }
            }
            
            VStack(alignment: .leading) {
                Text(candidate.title)
                Text(candidate.authors.joined(separator: ", "))
                    .font(.footnote)
            }
        }
    }
}
