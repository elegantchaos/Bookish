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
      id: "success",
      result: .success([BookLookupCandidate(providerID: "success", title: "Dune")])
    )
    let failure = StubBookLookupProvider(
      id: "failure",
      result: .failure(StubError.expected)
    )
    let service = BookLookupService(providers: [success, failure])

    let result = await service.lookupBooks(matching: BookLookupQuery("Dune"))

    #expect(result.candidates == [BookLookupCandidate(providerID: "success", title: "Dune")])
    #expect(result.failures.map(\.providerID) == ["failure"])
  }

  /// Replaces and removes providers without affecting other registered providers.
  @Test
  func serviceReconfiguresProvidersByIdentifier() async {
    let original = StubBookLookupProvider(id: "provider", result: .success([]))
    let replacement = StubBookLookupProvider(
      id: "provider",
      result: .success(FakeBookLookupProvider.sampleCandidates)
    )
    let preserved = StubBookLookupProvider(id: "preserved", result: .success([]))
    let service = BookLookupService(providers: [original, preserved])

    await service.register(replacement)
    await service.unregister("preserved")

    let providers = await service.providers
    #expect(providers.map(\.id) == ["provider"])
    let result = await service.lookupBooks(matching: BookLookupQuery("test"))
    #expect(result.candidates == FakeBookLookupProvider.sampleCandidates)
  }
}
