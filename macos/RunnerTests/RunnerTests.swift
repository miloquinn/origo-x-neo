import XCTest
@testable import 开元阅读

class RunnerTests: XCTestCase {
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
