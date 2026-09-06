// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishRecord
import SwiftUI

/// Displays the ordered fields and embedded sections from a record presentation.
public struct BookishRecordFieldsView<SectionContent: View>: View {
  private let presentation: BookishRecordPresentation
  private let viewerRegistry: BookishValueViewerRegistry
  private let mode: BookishValuePresentationMode
  private let sectionView: (BookishRecordID) -> SectionContent

  /// Creates fields from a presentation and a view builder for linked layout content.
  public init(
    presentation: BookishRecordPresentation,
    viewerRegistry: BookishValueViewerRegistry = .init(),
    mode: BookishValuePresentationMode = .viewing,
    @ViewBuilder sectionView: @escaping (BookishRecordID) -> SectionContent
  ) {
    self.presentation = presentation
    self.viewerRegistry = viewerRegistry
    self.mode = mode
    self.sectionView = sectionView
  }

  /// The fields and linked sections declared by the presentation layout.
  public var body: some View {
    ForEach(presentation.layoutItems(for: mode)) { item in
      if case .field(let field) = item {
        LabeledContent {
          viewerRegistry.view(for: field, mode: mode)
        } label: {
          if let icon = field.icon {
            Label(field.label, systemImage: icon)
          } else {
            Text(field.label)
          }
        }
      }

      if case .section(let sectionID) = item {
        sectionView(sectionID)
      }
    }
  }
}
