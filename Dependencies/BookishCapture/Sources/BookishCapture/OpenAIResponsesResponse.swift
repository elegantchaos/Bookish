// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 12/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

struct OpenAIResponsesResponse: Decodable {
  let output: [OutputItem]
  let rawOutputText: String?

  var outputText: String? {
    output.lazy
      .flatMap(\.content)
      .first(where: { $0.type == "output_text" })?
      .text ?? rawOutputText
  }

  enum CodingKeys: String, CodingKey {
    case output
    case rawOutputText = "output_text"
  }

  init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    output = try container.decodeIfPresent([OutputItem].self, forKey: .output) ?? []
    rawOutputText = try container.decodeIfPresent(String.self, forKey: .rawOutputText)
  }

  struct OutputItem: Decodable {
    let content: [OutputContent]
  }

  struct OutputContent: Decodable {
    let type: String
    let text: String?
  }
}
