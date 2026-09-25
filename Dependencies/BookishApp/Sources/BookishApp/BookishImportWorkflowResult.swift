import BookishRecord

/// The outcome shown in the Import workflow after a reviewed proposal is applied.
public struct BookishImportWorkflowResult: Equatable, Sendable {
  public let sourceName: String
  public let importedRecords: [BookishRecord]
  public let skippedCount: Int
  public let reusedCount: Int

  public init(
    sourceName: String, importedRecords: [BookishRecord], skippedCount: Int, reusedCount: Int
  ) {
    self.sourceName = sourceName
    self.importedRecords = importedRecords
    self.skippedCount = skippedCount
    self.reusedCount = reusedCount
  }
}
