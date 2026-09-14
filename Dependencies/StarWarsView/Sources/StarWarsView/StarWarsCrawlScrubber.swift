// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 14/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

/// Provides an interactive preview of every point in the crawl animation.
private struct StarWarsCrawlScrubber: View {
  /// The text to preview.
  let text: String

  /// The manually selected normalized crawl position.
  @State private var progress = 0.0

  /// The typography selected for the preview.
  @State private var layout: StarWarsCrawlLayout = .loose

  /// The camera selected for the preview.
  @State private var camera = StarWarsCrawlCamera.standard

  /// Renders the crawl above a phase slider.
  var body: some View {
    VStack(spacing: 16) {
      StarWarsCrawlScene(
        text: text,
        progress: CGFloat(progress),
        layout: layout,
        camera: camera
      )
      .frame(minHeight: 360)

      VStack(alignment: .leading) {
        Picker("Text Layout", selection: $layout) {
          Text("Loose").tag(StarWarsCrawlLayout.loose)
          Text("Dense").tag(StarWarsCrawlLayout.denseJustified)
        }
        .pickerStyle(.segmented)

        Text("Crawl Progress")

        Slider(value: $progress, in: 0...1)

        Text(progress, format: .number.precision(.fractionLength(1)))
          .font(.caption.monospacedDigit())
          .foregroundStyle(.secondary)

        StarWarsCrawlTuningControls(camera: $camera)
      }
      .padding(.horizontal)
    }
    .padding(.vertical)
    .background(.black)
  }
}

/// Provides development controls for experimenting with the crawl projection.
private struct StarWarsCrawlTuningControls: View {
  /// The camera whose values the controls adjust.
  @Binding var camera: StarWarsCrawlCamera

  /// Renders the independently adjustable camera parameters.
  var body: some View {
    Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
      GridRow {
        Text("Tilt")
        Slider(value: $camera.tiltDegrees, in: 65...85, step: 1)
        Text(camera.tiltDegrees, format: .number.precision(.fractionLength(0)))
          .monospacedDigit()
      }

      GridRow {
        Text("Perspective")
        Slider(value: $camera.perspective, in: 0.4...1.5, step: 0.1)
        Text(camera.perspective, format: .number.precision(.fractionLength(1)))
          .monospacedDigit()
      }

      GridRow {
        Text("Column Width")
        Slider(value: $camera.maximumTextWidth, in: 280...480, step: 10)
        Text(camera.maximumTextWidth, format: .number.precision(.fractionLength(0)))
          .monospacedDigit()
      }
    }
    .font(.caption)
  }
}

#Preview("Scrubbed Crawl") {
  StarWarsCrawlScrubber(text: StarWarsView.defaultText)
    .frame(width: 640, height: 560)
}
