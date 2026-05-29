import XCTest

@testable import DatastorePrototypeApp

final class DatastorePrototypeAppTests: XCTestCase {
  @MainActor
  func testHarnessStartsInLoadingState() {
    let harness = DatastorePrototypeHarness()

    XCTAssertEqual(harness.status, "Loading")
    XCTAssertTrue(harness.records.isEmpty)
    XCTAssertTrue(harness.mutations.isEmpty)
  }
}
