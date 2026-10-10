import CryptoKit
import Foundation

#if canImport(Flutter)
import Flutter
#elseif canImport(FlutterMacOS)
import FlutterMacOS
#endif

#if canImport(UIKit)
import UIKit
#endif

#if canImport(IOKit)
import IOKit
#endif

/// Native transport for the versioned iCloud sync tree.
///
/// The bridge deliberately exposes only immutable asset objects and one JSON
/// document per device. Conflict resolution and record semantics stay in Dart.
final class ICloudSyncBridge {
  static let channelName = "com.niki.xxread/icloud_sync"
  static let containerIdentifier = "iCloud.com.niki.xxread"
  static let metadataTimeout: TimeInterval = 15
  static let downloadTimeout: TimeInterval = 120

  private let fileManager: FileManager
  private let workQueue = DispatchQueue(
    label: "com.niki.xxread.icloud-sync",
    qos: .utility
  )

  #if canImport(Flutter) || canImport(FlutterMacOS)
  private let channel: FlutterMethodChannel

  init(messenger: FlutterBinaryMessenger, fileManager: FileManager = .default) {
    self.fileManager = fileManager
    channel = FlutterMethodChannel(
      name: Self.channelName,
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
  }
  #else
  init(fileManager: FileManager = .default) {
    self.fileManager = fileManager
  }
  #endif

  static func isAllowedRelativePath(_ path: String) -> Bool {
    guard !path.isEmpty,
          !path.hasPrefix("/"),
          !path.contains("\\"),
          !path.contains("\0") else {
      return false
    }
    let components = path.split(separator: "/", omittingEmptySubsequences: false)
    guard components.count == 3,
          components[0] == "sync-v1" else {
      return false
    }

    let leaf = String(components[2])
    switch components[1] {
    case "devices":
      guard leaf.hasSuffix(".json") else { return false }
      let identifier = String(leaf.dropLast(5))
      return UUID(uuidString: identifier) != nil
    case "assets":
      return leaf.count == 64 && leaf.allSatisfy {
        ("0"..."9").contains($0) || ("a"..."f").contains($0)
      }
    default:
      return false
    }
  }

  static func accountIdentifier(for token: Any) throws -> String {
    let archived = try NSKeyedArchiver.archivedData(
      withRootObject: token,
      requiringSecureCoding: false
    )
    return SHA256.hash(data: archived).map { String(format: "%02x", $0) }.joined()
  }

  static func sha256Hex(of url: URL) throws -> String {
    let handle = try FileHandle(forReadingFrom: url)
    defer { handle.closeFile() }
    var hasher = SHA256()
    while true {
      let chunk = handle.readData(ofLength: 1024 * 1024)
      if chunk.isEmpty { break }
      hasher.update(data: chunk)
    }
    return hasher.finalize().map { String(format: "%02x", $0) }.joined()
  }

  static func sha256Hex(of value: String) -> String {
    SHA256.hash(data: Data(value.utf8))
      .map { String(format: "%02x", $0) }
      .joined()
  }

  #if canImport(Flutter) || canImport(FlutterMacOS)
  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    workQueue.async { [weak self] in
      guard let self else { return }
      do {
        let value: Any?
        switch call.method {
        case "status":
          value = try self.status()
        case "list":
          let args = try Self.arguments(call.arguments)
          value = try self.list(expectedAccountID: try Self.string("accountId", in: args))
        case "read":
          let args = try Self.arguments(call.arguments)
          value = try self.read(
            path: try Self.string("path", in: args),
            destinationPath: try Self.string("destinationPath", in: args),
            expectedAccountID: try Self.string("accountId", in: args)
          )
        case "write":
          let args = try Self.arguments(call.arguments)
          value = try self.write(
            path: try Self.string("path", in: args),
            sourcePath: try Self.string("sourcePath", in: args),
            expectedAccountID: try Self.string("accountId", in: args)
          )
        default:
          DispatchQueue.main.async { result(FlutterMethodNotImplemented) }
          return
        }
        DispatchQueue.main.async { result(value) }
      } catch {
        let bridgeError = (error as? ICloudSyncError) ?? .operationFailed(error.localizedDescription)
        DispatchQueue.main.async {
          result(FlutterError(
            code: bridgeError.code,
            message: bridgeError.localizedDescription,
            details: nil
          ))
        }
      }
    }
  }

  private static func arguments(_ value: Any?) throws -> [String: Any] {
    guard let args = value as? [String: Any] else { throw ICloudSyncError.invalidArguments }
    return args
  }

  private static func string(_ key: String, in args: [String: Any]) throws -> String {
    guard let value = args[key] as? String, !value.isEmpty else {
      throw ICloudSyncError.invalidArguments
    }
    return value
  }
  #endif

  private func status() throws -> [String: Any] {
    let accountID = try currentAccountIdentifier()
    var response: [String: Any] = [
      "available": accountID != nil && containerURL() != nil,
      "deviceName": Self.deviceName,
    ]
    if let accountID { response["accountId"] = accountID }
    if let installationIdentity = Self.installationIdentity {
      response["installationIdentity"] = installationIdentity
    }
    return response
  }

  private func list(expectedAccountID: String) throws -> [[String: Any]] {
    let documents = try documentsURL(expectedAccountID: expectedAccountID)
    return try remoteEntries(documentsRoot: documents, expectedAccountID: expectedAccountID)
      .compactMap { entry in
      guard try !isSymbolicLink(entry.url) else {
        return nil
      }
      var value: [String: Any] = ["path": entry.path]
      if let size = entry.item.value(forAttribute: NSMetadataItemFSSizeKey) as? NSNumber {
        value["bytes"] = size.int64Value
      }
      if let uploaded = entry.item.value(
        forAttribute: NSMetadataUbiquitousItemIsUploadedKey
      ) as? NSNumber {
        value["uploaded"] = uploaded.boolValue
      }
      if let error = entry.item.value(
        forAttribute: NSMetadataUbiquitousItemUploadingErrorKey
      ) as? NSError {
        value["uploadError"] = error.localizedDescription
      }
      return value
    }.sorted { ($0["path"] as? String ?? "") < ($1["path"] as? String ?? "") }
  }

  private func read(
    path: String,
    destinationPath: String,
    expectedAccountID: String
  ) throws -> String {
    let documents = try documentsURL(expectedAccountID: expectedAccountID)
    let logicalSource = try validatedCloudURL(path: path, documentsRoot: documents)
    guard let entry = try remoteEntry(
      path: path,
      documentsRoot: documents,
      expectedAccountID: expectedAccountID
    ) else {
      throw ICloudSyncError.notFound
    }
    try rejectCloudPathSymbolicLinks(logicalSource, documentsRoot: documents)
    try startDownloading(entryURL: entry.url, logicalURL: logicalSource)
    let source = try waitForDownload(
      entry.url,
      logicalURL: logicalSource,
      expectedAccountID: expectedAccountID
    )

    let destination = URL(fileURLWithPath: destinationPath).standardizedFileURL
    guard destination.path == destinationPath || destination.path == URL(fileURLWithPath: destinationPath).path else {
      throw ICloudSyncError.invalidArguments
    }
    try rejectSymbolicLinksInExistingPath(destination)
    try coordinatedCopy(from: source, to: destination)
    try verifyAccount(expectedAccountID)
    return destination.path
  }

  private func write(
    path: String,
    sourcePath: String,
    expectedAccountID: String
  ) throws -> [String: Any] {
    let documents = try documentsURL(expectedAccountID: expectedAccountID)
    let destination = try validatedCloudURL(path: path, documentsRoot: documents)
    let source = URL(fileURLWithPath: sourcePath).standardizedFileURL
    var isDirectory: ObjCBool = false
    guard fileManager.fileExists(atPath: source.path, isDirectory: &isDirectory), !isDirectory.boolValue else {
      throw ICloudSyncError.notFound
    }
    try rejectSymbolicLink(source)
    try rejectCloudPathSymbolicLinks(destination, documentsRoot: documents)
    let sourceHash = try Self.sha256Hex(of: source)
    if path.hasPrefix("sync-v1/assets/") {
      guard sourceHash == destination.lastPathComponent else {
        throw ICloudSyncError.integrityMismatch
      }
    }

    if let existing = try remoteEntry(
      path: path,
      documentsRoot: documents,
      expectedAccountID: expectedAccountID
    ) {
      try startDownloading(entryURL: existing.url, logicalURL: destination)
      let existingURL = try waitForDownload(
        existing.url,
        logicalURL: destination,
        expectedAccountID: expectedAccountID
      )
      if try Self.sha256Hex(of: existingURL) == sourceHash {
        try verifyAccount(expectedAccountID)
        return try uploadResult(for: existingURL, metadataItem: existing.item)
      }
    }

    try coordinatedCopy(from: source, to: destination)
    try verifyAccount(expectedAccountID)
    return try uploadResult(for: destination, metadataItem: nil)
  }

  private func currentAccountIdentifier() throws -> String? {
    guard let token = fileManager.ubiquityIdentityToken else { return nil }
    return try Self.accountIdentifier(for: token)
  }

  private func verifyAccount(_ expected: String) throws {
    guard let current = try currentAccountIdentifier() else {
      throw ICloudSyncError.iCloudUnavailable
    }
    guard current == expected else { throw ICloudSyncError.accountChanged }
  }

  private func containerURL() -> URL? {
    fileManager.url(forUbiquityContainerIdentifier: Self.containerIdentifier)
  }

  private func documentsURL(expectedAccountID: String) throws -> URL {
    try verifyAccount(expectedAccountID)
    guard let container = containerURL() else { throw ICloudSyncError.iCloudUnavailable }
    let documents = container.appendingPathComponent("Documents", isDirectory: true)
    try fileManager.createDirectory(at: documents, withIntermediateDirectories: true)
    try verifyAccount(expectedAccountID)
    return documents
  }

  private func validatedCloudURL(path: String, documentsRoot: URL) throws -> URL {
    guard Self.isAllowedRelativePath(path) else { throw ICloudSyncError.invalidPath }
    let resolved = documentsRoot.appendingPathComponent(path).standardizedFileURL
    let prefix = documentsRoot.standardizedFileURL.path + "/"
    guard resolved.path.hasPrefix(prefix) else { throw ICloudSyncError.invalidPath }
    return resolved
  }

  private func relativePath(for url: URL, documentsRoot: URL) -> String? {
    let root = documentsRoot.standardizedFileURL.path + "/"
    let path = url.standardizedFileURL.path
    guard path.hasPrefix(root) else { return nil }
    let relative = String(path.dropFirst(root.count))
    if Self.isAllowedRelativePath(relative) { return relative }

    var components = relative.split(separator: "/", omittingEmptySubsequences: false)
    guard components.count == 3 else { return nil }
    let placeholder = String(components[2])
    guard placeholder.hasPrefix("."), placeholder.hasSuffix(".icloud") else { return nil }
    components[2] = Substring(placeholder.dropFirst().dropLast(7))
    let restored = components.joined(separator: "/")
    return Self.isAllowedRelativePath(restored) ? restored : nil
  }

  private func remoteEntries(
    documentsRoot: URL,
    expectedAccountID: String
  ) throws -> [RemoteEntry] {
    let root = documentsRoot.appendingPathComponent("sync-v1", isDirectory: true)
    let session = MetadataQuerySession(root: root)
    guard let items = session.run(timeout: Self.metadataTimeout) else {
      throw ICloudSyncError.metadataQueryTimedOut
    }
    try verifyAccount(expectedAccountID)
    return items.compactMap { item in
      guard let url = item.value(forAttribute: NSMetadataItemURLKey) as? URL,
            let path = relativePath(for: url, documentsRoot: documentsRoot),
            Self.isAllowedRelativePath(path) else {
        return nil
      }
      return RemoteEntry(path: path, url: url, item: item)
    }
  }

  private func remoteEntry(
    path: String,
    documentsRoot: URL,
    expectedAccountID: String
  ) throws -> RemoteEntry? {
    let logicalURL = try validatedCloudURL(path: path, documentsRoot: documentsRoot)
    if fileManager.fileExists(atPath: logicalURL.path) {
      return RemoteEntry(path: path, url: logicalURL, item: NSMetadataItem())
    }
    return try remoteEntries(
      documentsRoot: documentsRoot,
      expectedAccountID: expectedAccountID
    ).first { $0.path == path }
  }

  private func waitForDownload(
    _ url: URL,
    logicalURL: URL,
    expectedAccountID: String
  ) throws -> URL {
    let deadline = Date().addingTimeInterval(Self.downloadTimeout)
    while Date() < deadline {
      for candidate in url == logicalURL ? [url] : [url, logicalURL] {
        do {
          let values = try candidate.resourceValues(forKeys: [
            .ubiquitousItemDownloadingStatusKey,
            .ubiquitousItemDownloadingErrorKey,
          ])
          if let error = values.ubiquitousItemDownloadingError { throw error }
          if values.ubiquitousItemDownloadingStatus == .current {
            try verifyAccount(expectedAccountID)
            return candidate
          }
        } catch let error as NSError where error.domain == NSCocoaErrorDomain && error.code == NSFileNoSuchFileError {
          continue
        }
      }
      try verifyAccount(expectedAccountID)
      Thread.sleep(forTimeInterval: 0.2)
    }
    throw ICloudSyncError.downloadTimedOut
  }

  private func startDownloading(entryURL: URL, logicalURL: URL) throws {
    var lastError: Error?
    for candidate in entryURL == logicalURL ? [logicalURL] : [logicalURL, entryURL] {
      do {
        try fileManager.startDownloadingUbiquitousItem(at: candidate)
        return
      } catch {
        lastError = error
      }
    }
    throw lastError ?? ICloudSyncError.notFound
  }

  private func uploadResult(
    for url: URL,
    metadataItem: NSMetadataItem?
  ) throws -> [String: Any] {
    let values = try? url.resourceValues(forKeys: [
      .ubiquitousItemIsUploadedKey,
      .ubiquitousItemIsUploadingKey,
      .ubiquitousItemUploadingErrorKey,
    ])
    if let error = values?.ubiquitousItemUploadingError { throw error }
    if let error = metadataItem?.value(
      forAttribute: NSMetadataUbiquitousItemUploadingErrorKey
    ) as? NSError {
      throw error
    }
    let metadataUploaded = (
      metadataItem?.value(forAttribute: NSMetadataUbiquitousItemIsUploadedKey) as? NSNumber
    )?.boolValue
    let uploaded = values?.ubiquitousItemIsUploaded ?? metadataUploaded ?? false
    return [
      "uploaded": uploaded,
      "uploadPending": values?.ubiquitousItemIsUploading == true || !uploaded,
    ]
  }

  private func coordinatedCopy(from source: URL, to destination: URL) throws {
    let parent = destination.deletingLastPathComponent()
    try fileManager.createDirectory(at: parent, withIntermediateDirectories: true)
    let coordinator = NSFileCoordinator(filePresenter: nil)
    var coordinationError: NSError?
    var copyError: Error?
    var copied = false
    coordinator.coordinate(
      readingItemAt: source,
      options: [],
      writingItemAt: destination,
      options: .forReplacing,
      error: &coordinationError
    ) { coordinatedSource, coordinatedDestination in
      let temporary = coordinatedDestination.deletingLastPathComponent()
        .appendingPathComponent(".origo-icloud-\(UUID().uuidString).tmp")
      do {
        try? self.fileManager.removeItem(at: temporary)
        try self.fileManager.copyItem(at: coordinatedSource, to: temporary)
        if self.fileManager.fileExists(atPath: coordinatedDestination.path) {
          _ = try self.fileManager.replaceItemAt(
            coordinatedDestination,
            withItemAt: temporary,
            backupItemName: nil,
            options: []
          )
        } else {
          try self.fileManager.moveItem(at: temporary, to: coordinatedDestination)
        }
        copied = true
      } catch {
        copyError = error
        try? self.fileManager.removeItem(at: temporary)
      }
    }
    if let coordinationError { throw coordinationError }
    if let copyError { throw copyError }
    if !copied { throw ICloudSyncError.operationFailed("Coordinated copy did not run") }
  }

  private func rejectSymbolicLink(_ url: URL) throws {
    if try isSymbolicLink(url) { throw ICloudSyncError.symbolicLinkRejected }
  }

  private func isSymbolicLink(_ url: URL) throws -> Bool {
    guard fileManager.fileExists(atPath: url.path) else { return false }
    return try url.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink == true
  }

  private func rejectSymbolicLinksInExistingPath(_ url: URL) throws {
    var candidate = url.standardizedFileURL
    while candidate.path != "/" {
      if fileManager.fileExists(atPath: candidate.path), try isSymbolicLink(candidate) {
        throw ICloudSyncError.symbolicLinkRejected
      }
      candidate.deleteLastPathComponent()
    }
  }

  private func rejectCloudPathSymbolicLinks(_ url: URL, documentsRoot: URL) throws {
    let root = documentsRoot.standardizedFileURL
    var candidate = url.standardizedFileURL
    while candidate.path != root.path {
      guard candidate.path.hasPrefix(root.path + "/") else {
        throw ICloudSyncError.invalidPath
      }
      if fileManager.fileExists(atPath: candidate.path), try isSymbolicLink(candidate) {
        throw ICloudSyncError.symbolicLinkRejected
      }
      candidate.deleteLastPathComponent()
    }
  }

  private static var deviceName: String {
    #if os(iOS)
    return UIDevice.current.name
    #elseif os(macOS)
    return Host.current().localizedName ?? ProcessInfo.processInfo.hostName
    #else
    return ProcessInfo.processInfo.hostName
    #endif
  }

  /// A one-way binding to this physical installation. Dart uses it only to
  /// detect a device UUID copied by system migration or backup restore.
  private static var installationIdentity: String? {
    #if os(iOS)
    guard let identifier = UIDevice.current.identifierForVendor else { return nil }
    return sha256Hex(of: identifier.uuidString)
    #elseif os(macOS)
    guard let matching = IOServiceMatching("IOPlatformExpertDevice") else { return nil }
    let service = IOServiceGetMatchingService(kIOMainPortDefault, matching)
    guard service != 0 else { return nil }
    defer { IOObjectRelease(service) }
    guard let property = IORegistryEntryCreateCFProperty(
      service,
      "IOPlatformUUID" as CFString,
      kCFAllocatorDefault,
      0
    )?.takeRetainedValue() as? String,
      !property.isEmpty else {
      return nil
    }
    return sha256Hex(of: property)
    #else
    return nil
    #endif
  }
}

private struct RemoteEntry {
  let path: String
  let url: URL
  let item: NSMetadataItem
}

private final class MetadataQuerySession {
  private let query = NSMetadataQuery()
  private let root: URL
  private let completion = DispatchSemaphore(value: 0)
  private var observer: NSObjectProtocol?
  private var gatheredItems: [NSMetadataItem]?

  init(root: URL) {
    self.root = root
  }

  func run(timeout: TimeInterval) -> [NSMetadataItem]? {
    DispatchQueue.main.async { [self] in
      query.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
      query.predicate = NSPredicate(
        format: "%K BEGINSWITH %@",
        NSMetadataItemPathKey,
        root.standardizedFileURL.path + "/"
      )
      observer = NotificationCenter.default.addObserver(
        forName: .NSMetadataQueryDidFinishGathering,
        object: query,
        queue: .main
      ) { [weak self] _ in
        guard let self else { return }
        query.disableUpdates()
        gatheredItems = query.results.compactMap { $0 as? NSMetadataItem }
        query.stop()
        if let observer {
          NotificationCenter.default.removeObserver(observer)
          self.observer = nil
        }
        completion.signal()
      }
      if !query.start() {
        gatheredItems = nil
        if let observer { NotificationCenter.default.removeObserver(observer) }
        observer = nil
        completion.signal()
      }
    }

    if completion.wait(timeout: .now() + timeout) == .timedOut {
      DispatchQueue.main.async { [self] in
        query.stop()
        if let observer { NotificationCenter.default.removeObserver(observer) }
        observer = nil
      }
      return nil
    }
    return gatheredItems
  }
}

private enum ICloudSyncError: LocalizedError {
  case invalidArguments
  case invalidPath
  case symbolicLinkRejected
  case iCloudUnavailable
  case accountChanged
  case notFound
  case metadataQueryTimedOut
  case downloadTimedOut
  case integrityMismatch
  case operationFailed(String)

  var code: String {
    switch self {
    case .invalidArguments: return "invalid_args"
    case .invalidPath: return "invalid_path"
    case .symbolicLinkRejected: return "symlink_rejected"
    case .iCloudUnavailable: return "icloud_unavailable"
    case .accountChanged: return "icloud_account_changed"
    case .notFound: return "not_found"
    case .metadataQueryTimedOut: return "metadata_query_timeout"
    case .downloadTimedOut: return "download_timeout"
    case .integrityMismatch: return "integrity_mismatch"
    case .operationFailed: return "operation_failed"
    }
  }

  var errorDescription: String? {
    switch self {
    case .invalidArguments: return "Expected non-empty string arguments"
    case .invalidPath: return "The iCloud sync path is not allowed"
    case .symbolicLinkRejected: return "Symbolic links are not allowed for iCloud sync"
    case .iCloudUnavailable: return "iCloud Drive is unavailable"
    case .accountChanged: return "The signed-in iCloud account changed during sync"
    case .notFound: return "The requested sync file does not exist"
    case .metadataQueryTimedOut: return "Timed out while discovering iCloud sync files"
    case .downloadTimedOut: return "Timed out while downloading the iCloud sync file"
    case .integrityMismatch: return "The sync asset does not match its SHA-256 path"
    case .operationFailed(let message): return message
    }
  }
}
