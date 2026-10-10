import XCTest
@testable import Runner

class RunnerTests: XCTestCase {
  func testICloudSyncPathAllowlistRejectsTraversalAndUnexpectedNames() {
    XCTAssertTrue(ICloudSyncBridge.isAllowedRelativePath(
      "sync-v1/devices/6a81a738-33ab-4aef-b2e8-84d09da6ce94.json"
    ))
    XCTAssertTrue(ICloudSyncBridge.isAllowedRelativePath(
      "sync-v1/assets/\(String(repeating: "a", count: 64))"
    ))
    XCTAssertFalse(ICloudSyncBridge.isAllowedRelativePath(
      "sync-v1/devices/../private.json"
    ))
    XCTAssertFalse(ICloudSyncBridge.isAllowedRelativePath(
      "sync-v1/assets/\(String(repeating: "A", count: 64))"
    ))
    XCTAssertFalse(ICloudSyncBridge.isAllowedRelativePath("sync-v1/devices/device.json"))
  }

  func testICloudAccountIdentifierIsStableAndDoesNotExposeToken() throws {
    let token = "private-ubiquity-token"
    let first = try ICloudSyncBridge.accountIdentifier(for: token)
    let second = try ICloudSyncBridge.accountIdentifier(for: token)
    XCTAssertEqual(first, second)
    XCTAssertEqual(first.count, 64)
    XCTAssertFalse(first.contains(token))
  }

  func testICloudAssetHashStreamsFileContents() throws {
    let file = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
    try Data("abc".utf8).write(to: file)
    defer { try? FileManager.default.removeItem(at: file) }
    XCTAssertEqual(
      try ICloudSyncBridge.sha256Hex(of: file),
      "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
    )
  }

  func testICloudInstallationIdentityHashDoesNotExposeDeviceIdentifier() {
    let identifier = "00000000-0000-0000-0000-000000000001"
    let digest = ICloudSyncBridge.sha256Hex(of: identifier)
    XCTAssertEqual(digest.count, 64)
    XCTAssertFalse(digest.contains(identifier))
  }

  func testICloudLocatorStaysInsideBooksDirectory() throws {
    let root = URL(fileURLWithPath: "/tmp/OrigoReader/Documents/books", isDirectory: true)
    let resolved = try StorageBridge.validatedSourceURL(
      locator: "novels/example.epub",
      root: root
    )

    XCTAssertEqual(
      resolved.path,
      "/tmp/OrigoReader/Documents/books/novels/example.epub"
    )
  }

  func testICloudLocatorRejectsParentTraversal() {
    let root = URL(fileURLWithPath: "/tmp/OrigoReader/Documents/books", isDirectory: true)

    XCTAssertThrowsError(
      try StorageBridge.validatedSourceURL(
        locator: "../private/book.epub",
        root: root
      )
    )
    XCTAssertThrowsError(
      try StorageBridge.validatedSourceURL(
        locator: "/private/book.epub",
        root: root
      )
    )
  }

  func testIncomingBookDisplayNameIsBasenameAndSanitized() {
    XCTAssertEqual(
      IncomingBookInbox.sanitizedDisplayName(
        "../unsafe:book.epub",
        fallbackExtension: "epub"
      ),
      "unsafe_book.epub"
    )
    XCTAssertEqual(
      IncomingBookInbox.sanitizedDisplayName("..", fallbackExtension: "txt"),
      "book.txt"
    )
  }

  func testIncomingBookURLFilteringIsNarrowAndDeduplicated() {
    let supported = URL(fileURLWithPath: "/tmp/book.epub")
    let urls = IncomingBookInbox.uniqueSupportedFileURLs([
      supported,
      supported,
      URL(fileURLWithPath: "/tmp/archive.zip"),
      URL(string: "https://example.com/book.epub")!,
    ])

    XCTAssertEqual(urls, [supported])
  }

  func testSharedPayloadURLStaysInsidePayloadDirectory() throws {
    let root = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
      .appendingPathComponent("payloads", isDirectory: true)
    let requestDirectory = root.appendingPathComponent("request-id", isDirectory: true)
    let bookURL = requestDirectory.appendingPathComponent("book.pdf")
    try FileManager.default.createDirectory(
      at: requestDirectory,
      withIntermediateDirectories: true
    )
    try Data("%PDF-test".utf8).write(to: bookURL)
    defer { try? FileManager.default.removeItem(at: root.deletingLastPathComponent()) }
    let resolved = try IncomingBookInbox.validatedSharedPayloadURL(
      relativePath: "request-id/book.pdf",
      root: root,
      expectedRequestID: "request-id"
    )
    XCTAssertEqual(resolved.path, bookURL.path)
    XCTAssertThrowsError(
      try IncomingBookInbox.validatedSharedPayloadURL(
        relativePath: "../private/book.pdf",
        root: root,
        expectedRequestID: "request-id"
      )
    )
    XCTAssertThrowsError(
      try IncomingBookInbox.validatedSharedPayloadURL(
        relativePath: "another-request/book.pdf",
        root: root,
        expectedRequestID: "request-id"
      )
    )
  }

  func testIncomingRequestIDCannotEscapeInbox() {
    XCTAssertTrue(IncomingBookInbox.isValidRequestID("6a81a738-33ab-4aef-b2e8-84d09da6ce94"))
    XCTAssertFalse(IncomingBookInbox.isValidRequestID("../request"))
    XCTAssertFalse(IncomingBookInbox.isValidRequestID("REQUEST"))
  }

  func testIncomingPermissionFailureUsesStableErrorCode() {
    let error = NSError(
      domain: NSCocoaErrorDomain,
      code: NSFileReadNoPermissionError
    )
    XCTAssertEqual(IncomingBookInbox.errorCode(for: error), "file_access_lost")
  }

  func testIncomingDisplayNameLimitUsesUTF8BytesAndPreservesExtension() {
    let name = IncomingBookInbox.sanitizedDisplayName(
      "\(String(repeating: "书", count: 100)).epub",
      fallbackExtension: "epub"
    )
    XCTAssertLessThanOrEqual(name.lengthOfBytes(using: .utf8), 180)
    XCTAssertEqual((name as NSString).pathExtension, "epub")
  }
}
