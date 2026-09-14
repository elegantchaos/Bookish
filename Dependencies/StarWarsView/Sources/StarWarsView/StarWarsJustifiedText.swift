// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 14/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

#if os(macOS)
  import AppKit

  /// Hosts AppKit's fully justified text layout inside the SwiftUI crawl.
  struct StarWarsJustifiedText: NSViewRepresentable {
    /// The text to lay out.
    let text: String

    /// The width available to the text container.
    let width: CGFloat

    /// Creates the non-editable text field that performs the platform layout.
    func makeNSView(context: Context) -> NSTextField {
      let textField = NSTextField(wrappingLabelWithString: text)
      configure(textField)
      return textField
    }

    /// Updates the text field when SwiftUI changes its inputs.
    func updateNSView(_ textField: NSTextField, context: Context) {
      configure(textField)
    }

    /// Calculates the wrapped height for SwiftUI's proposed width.
    func sizeThatFits(
      _ proposal: ProposedViewSize,
      nsView textField: NSTextField,
      context: Context
    ) -> CGSize? {
      let width = proposal.width ?? width
      let bounds = NSRect(x: 0, y: 0, width: width, height: .greatestFiniteMagnitude)
      let height = textField.cell?.cellSize(forBounds: bounds).height ?? 0

      return CGSize(width: width, height: height)
    }

    /// Applies the compact visual treatment and justified paragraph style.
    private func configure(_ textField: NSTextField) {
      textField.stringValue = text
      textField.alignment = .justified
      textField.font = .systemFont(
        ofSize: NSFont.preferredFont(forTextStyle: .title1).pointSize, weight: .bold)
      textField.textColor = .yellow
      textField.maximumNumberOfLines = 0
      textField.lineBreakMode = .byWordWrapping
      textField.cell?.wraps = true
      textField.cell?.isScrollable = false
    }
  }
#elseif os(iOS)
  import UIKit

  /// Hosts UIKit's fully justified text layout inside the SwiftUI crawl.
  struct StarWarsJustifiedText: UIViewRepresentable {
    /// The text to lay out.
    let text: String

    /// The width available to the text container.
    let width: CGFloat

    /// Creates the label that performs the platform layout.
    func makeUIView(context: Context) -> UILabel {
      let label = UILabel()
      configure(label)
      return label
    }

    /// Updates the label when SwiftUI changes its inputs.
    func updateUIView(_ label: UILabel, context: Context) {
      configure(label)
    }

    /// Calculates the wrapped height for SwiftUI's proposed width.
    func sizeThatFits(
      _ proposal: ProposedViewSize,
      uiView label: UILabel,
      context: Context
    ) -> CGSize? {
      let width = proposal.width ?? width

      return label.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
    }

    /// Applies the compact visual treatment and justified paragraph style.
    private func configure(_ label: UILabel) {
      label.text = text
      label.textAlignment = .justified
      label.font = .systemFont(
        ofSize: UIFont.preferredFont(forTextStyle: .title1).pointSize, weight: .bold)
      label.textColor = .yellow
      label.numberOfLines = 0
      label.lineBreakMode = .byWordWrapping
      label.adjustsFontForContentSizeCategory = true
    }
  }
#endif
