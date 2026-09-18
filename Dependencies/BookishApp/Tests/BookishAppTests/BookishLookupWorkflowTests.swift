// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishLookup
import Foundation
import Settings
import Testing

@testable import BookishApp

/// Verifies lookup-provider selection and availability in the application workflow.
@MainActor
struct BookishLookupWorkflowTests {
  /// Restores a supported provider choice and persists a newly selected provider.
  @Test
  func selectedProviderRestoresAndPersistsInSettings() throws {
    let suiteName = "BookishLookupWorkflowTests-\(UUID().uuidString)"
    let settings = try #require(UserDefaults(suiteName: suiteName))
    defer { settings.removePersistentDomain(forName: suiteName) }
    settings.set(.openLibrary, forKey: .bookLookupProvider)
    let workflow = BookishLookupWorkflowService(
      providers: [FakeBookLookupProvider(), OpenLibraryLookupProvider()],
      settings: settings
    )

    #expect(workflow.selectedProviderID == .openLibrary)

    workflow.selectProvider(.fake)

    #expect(workflow.selectedProviderID == .fake)
    #expect(settings.value(forKey: .bookLookupProvider) == .fake)
  }

  /// Keeps an unavailable configured provider visible while selecting an available fallback.
  @Test
  func unavailableProviderFallsBackWithoutBeingRemoved() throws {
    let suiteName = "BookishLookupWorkflowTests-\(UUID().uuidString)"
    let settings = try #require(UserDefaults(suiteName: suiteName))
    defer { settings.removePersistentDomain(forName: suiteName) }
    settings.set(.googleBooks, forKey: .bookLookupProvider)
    let workflow = BookishLookupWorkflowService(
      providers: [FakeBookLookupProvider(), GoogleBooksLookupProvider(apiKey: nil)],
      settings: settings
    )

    #expect(workflow.providers.map(\.id).contains(.googleBooks))
    #expect(!workflow.isProviderSupported(.googleBooks))
    #expect(workflow.selectedProviderID == .fake)
  }
}
