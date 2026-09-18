// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Testing

@testable import BookishLookup

/// Verifies lookup-provider composition and provider-specific result reporting.
struct BookLookupServiceTests {
  @Test
  func fakeProviderReturnsItsSampleCandidates() async throws {
    let provider = FakeBookLookupProvider()

    let candidates = try await provider.lookupBooks(matching: BookLookupQuery("Dune"))

    #expect(candidates == FakeBookLookupProvider.sampleCandidates)
  }

  @Test
  func serviceCollectsCandidatesAndProviderFailures() async {
    let success = StubBookLookupProvider(
      id: .fake,
      result: .success([BookLookupCandidate(providerID: .fake, title: "Dune")])
    )
    let failure = StubBookLookupProvider(
      id: .openLibrary,
      result: .failure(StubError.expected)
    )
    let service = BookLookupService(providers: [success, failure])

    let result = await service.lookupBooks(matching: BookLookupQuery("Dune"))

    #expect(result.candidates == [BookLookupCandidate(providerID: .fake, title: "Dune")])
    #expect(result.failures.map(\.providerID) == [.openLibrary])
  }

  /// Replaces and removes providers without affecting other registered providers.
  @Test
  func serviceReconfiguresProvidersByIdentifier() async {
    let original = StubBookLookupProvider(id: .googleBooks, result: .success([]))
    let replacement = StubBookLookupProvider(
      id: .googleBooks,
      result: .success(FakeBookLookupProvider.sampleCandidates)
    )
    let preserved = StubBookLookupProvider(id: .openLibrary, result: .success([]))
    let service = BookLookupService(providers: [original, preserved])

    await service.register(replacement)
    await service.unregister(.openLibrary)

    let providers = await service.providers
    #expect(providers.map(\.id) == [.googleBooks])
    let result = await service.lookupBooks(matching: BookLookupQuery("test"))
    #expect(result.candidates == FakeBookLookupProvider.sampleCandidates)
  }
}
