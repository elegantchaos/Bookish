// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 12/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Decodes the subset of a Responses API response used by the recognizer.
struct OpenAIResponsesResponse: Decodable {
  /// The structured output items returned by the API.
  let output: [OutputItem]

  /// The API's convenience text output, when supplied.
  let rawOutputText: String?

  /// The first structured text output, falling back to the convenience text output.
  var outputText: String? {
    output.lazy
      .flatMap(\.content)
      .first(where: { $0.type == "output_text" })?
      .text ?? rawOutputText
  }

  /// Maps the API's snake-case fields to Swift properties.
  enum CodingKeys: String, CodingKey {
    case output
    case rawOutputText = "output_text"
  }

  /// Decodes the response while treating a missing output array as empty.
  init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    output = try container.decodeIfPresent([OutputItem].self, forKey: .output) ?? []
    rawOutputText = try container.decodeIfPresent(String.self, forKey: .rawOutputText)
  }

  /// Represents an API output item.
  struct OutputItem: Decodable {
    /// The content fragments in the item.
    let content: [OutputContent]
  }

  /// Represents an API output-content fragment.
  struct OutputContent: Decodable {
    /// The API type of the fragment.
    let type: String

    /// The text in the fragment, when present.
    let text: String?
  }
}
