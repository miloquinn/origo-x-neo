import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private static let desktopWindowChannelName = "com.niki.xxread/desktop_window"
  private static let frameAutosaveName = "origo-x-main-window"

  private var appDistributionBridge: AppDistributionBridge?
  private var sourceBrowserSessionBridge: SourceBrowserSessionBridge?
  private var desktopWindowChannel: FlutterMethodChannel?
  private var closeRequestPending = false
  private var allowClose = false

  override func awakeFromNib() {
    setFrameAutosaveName(Self.frameAutosaveName)
    setFrameUsingName(Self.frameAutosaveName)
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    appDistributionBridge = AppDistributionBridge(
      messenger: flutterViewController.engine.binaryMessenger
    )
    sourceBrowserSessionBridge = SourceBrowserSessionBridge(
      messenger: flutterViewController.engine.binaryMessenger,
      parentWindow: self
    )
    desktopWindowChannel = FlutterMethodChannel(
      name: Self.desktopWindowChannelName,
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    RegisterGeneratedPlugins(registry: flutterViewController)
    registerForDraggedTypes([.fileURL])

    super.awakeFromNib()
  }

  override func performClose(_ sender: Any?) {
    if allowClose {
      super.performClose(sender)
      return
    }
    guard !closeRequestPending, let desktopWindowChannel else { return }
    closeRequestPending = true
    desktopWindowChannel.invokeMethod("requestClose", arguments: nil) { [weak self] result in
      guard let self else { return }
      self.closeRequestPending = false
      if result as? Bool == true {
        self.makeKeyAndOrderFront(nil)
        return
      }
      self.allowClose = true
      self.performClose(sender)
    }
  }

  func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
    return supportedDraggedBookPaths(from: sender).isEmpty ? [] : .copy
  }

  func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
    return supportedDraggedBookPaths(from: sender).isEmpty ? [] : .copy
  }

  func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
    let paths = supportedDraggedBookPaths(from: sender)
    return !paths.isEmpty && paths.count <= AppDelegate.maximumIncomingItems
  }

  func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
    let paths = supportedDraggedBookPaths(from: sender)
    guard !paths.isEmpty,
          paths.count <= AppDelegate.maximumIncomingItems,
          let appDelegate = NSApp.delegate as? AppDelegate else {
      return false
    }
    appDelegate.enqueueIncomingFiles(paths)
    return true
  }

  private func supportedDraggedBookPaths(from sender: NSDraggingInfo) -> [String] {
    let options: [NSPasteboard.ReadingOptionKey: Any] = [
      .urlReadingFileURLsOnly: true,
    ]
    guard let urls = sender.draggingPasteboard.readObjects(
      forClasses: [NSURL.self],
      options: options
    ) as? [URL] else {
      return []
    }
    return urls.compactMap { url in
      guard url.isFileURL,
            AppDelegate.supportsIncomingBook(url.pathExtension) else {
        return nil
      }
      return url.standardizedFileURL.path
    }
  }
}
