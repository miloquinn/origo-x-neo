import XCTest
@testable import 开元阅读

class RunnerTests: XCTestCase {
  func testICloudSyncPathAllowlistIsSharedWithIOS() {
    XCTAssertTrue(ICloudSyncBridge.isAllowedRelativePath(
      "sync-v1/devices/6a81a738-33ab-4aef-b2e8-84d09da6ce94.json"
    ))
    XCTAssertTrue(ICloudSyncBridge.isAllowedRelativePath(
      "sync-v1/assets/\(String(repeating: "0", count: 64))"
    ))
    XCTAssertFalse(ICloudSyncBridge.isAllowedRelativePath("../sync-v1/devices/device.json"))
    XCTAssertFalse(ICloudSyncBridge.isAllowedRelativePath("sync-v1/assets/file.txt"))
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

  func testICloudInstallationIdentityHashDoesNotExposePlatformUUID() {
    let identifier = "00000000-0000-0000-0000-000000000001"
    let digest = ICloudSyncBridge.sha256Hex(of: identifier)
    XCTAssertEqual(digest.count, 64)
    XCTAssertFalse(digest.contains(identifier))
  }

  func testMacAppStoreReceiptRequiresAnExistingReceiptFile() {
    let receiptURL = URL(
      fileURLWithPath: "/Applications/OrigoReader.app/Contents/_MASReceipt/receipt"
    )
    XCTAssertTrue(macAppStoreReceiptExists(receiptURL: receiptURL) { $0 == receiptURL.path })
    XCTAssertFalse(macAppStoreReceiptExists(receiptURL: receiptURL) { _ in false })
    XCTAssertFalse(macAppStoreReceiptExists(receiptURL: nil) { _ in true })
  }

  func testDesktopDropAcceptsEveryFormatExposedByTheBookPicker() {
    let supported = [
      "txt", "epub", "pdf", "mobi", "azw", "azw3", "fb2", "rtf",
      "doc", "docx", "html", "htm", "xhtml", "md", "markdown",
      "cbz", "cbt", "cbr", "cb7",
    ]

    for fileExtension in supported {
      XCTAssertTrue(
        AppDelegate.supportsIncomingBook(fileExtension),
        "Expected .\(fileExtension) to be accepted by desktop drop"
      )
    }
    XCTAssertTrue(AppDelegate.supportsIncomingBook("EPUB"))
    XCTAssertFalse(AppDelegate.supportsIncomingBook("zip"))
    XCTAssertFalse(AppDelegate.supportsIncomingBook("exe"))
  }
}

/// Keep this aligned with `MacAppStoreReceipt.exists` in AppDistributionBridge.swift.
private func macAppStoreReceiptExists(
  receiptURL: URL?,
  fileExists: (String) -> Bool
) -> Bool {
  guard let receiptURL else { return false }
  return fileExists(receiptURL.path)
}
