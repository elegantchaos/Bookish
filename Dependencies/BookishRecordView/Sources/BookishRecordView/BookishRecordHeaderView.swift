import SwiftUI

/// Displays the identity fields that introduce a record before its properties.
public struct BookishRecordHeaderView: View {
  private let header: BookishRecordHeader

  @ScaledMetric(relativeTo: .title) private var thumbnailWidth = 80.0
  @ScaledMetric(relativeTo: .title) private var thumbnailHeight = 120.0

  /// Creates a header view for resolved record identity fields.
  public init(header: BookishRecordHeader) {
    self.header = header
  }

  /// The visual representation of the record identity fields.
  public var body: some View {
    HStack(alignment: .top) {
      if let thumbnailURL = header.thumbnailURL {
        AsyncImage(url: thumbnailURL) { image in
          image
            .resizable()
            .scaledToFit()
        } placeholder: {
          Image(systemName: "photo")
            .imageScale(.large)
            .foregroundStyle(.secondary)
        }
        .frame(width: thumbnailWidth, height: thumbnailHeight)
        .clipShape(.rect(cornerRadius: 8))
        .accessibilityHidden(true)
      }

      VStack(alignment: .leading) {
        if let title = header.title {
          Text(title)
            .font(.title)
            .bold()
        }

        if let subtitle = header.subtitle {
          Text(subtitle)
            .font(.headline)
            .foregroundStyle(.secondary)
        }
      }
    }
  }
}
