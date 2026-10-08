import Flutter
import UIKit
import Darwin

final class AuthCallbackBridge {
  static let shared = AuthCallbackBridge()
  private var channel: FlutterMethodChannel?
  private var pending: String?

  static func isCallback(_ url: URL) -> Bool {
    url.scheme?.lowercased() == "xxread"
      && url.host?.lowercased() == "auth"
      && url.path == "/device"
  }

  func attach(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "com.niki.xxread/account_auth",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "getInitialAuthCallback" else {
        result(FlutterMethodNotImplemented)
        return
      }
      result(self?.pending)
      self?.pending = nil
    }
    self.channel = channel
  }

  func accept(urls: [URL]) {
    guard let url = urls.first(where: Self.isCallback) else { return }
    pending = url.absoluteString
    channel?.invokeMethod("onAuthCallback", arguments: url.absoluteString)
  }
}

@objc(ReaderFlutterViewController) class ReaderFlutterViewController: FlutterViewController {
  private var readerImmersiveEnabled = false {
    didSet {
      if oldValue != readerImmersiveEnabled {
        refreshImmersiveUI()
      }
    }
  }

  override var prefersHomeIndicatorAutoHidden: Bool {
    readerImmersiveEnabled
  }

  override var prefersStatusBarHidden: Bool {
    readerImmersiveEnabled
  }

  override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
    .fade
  }

  override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
    // Keep the Home Indicator visually hidden in reader modes, but let iOS
    // claim edge gestures immediately. Deferring every edge can deliver the
    // beginning of a bottom app-switcher swipe to Flutter's page-turn views,
    // which may settle on an adjacent page when the system takes over.
    []
  }

  @objc func setReaderImmersiveEnabled(_ enabled: Bool) {
    readerImmersiveEnabled = enabled
    if enabled {
      refreshImmersiveUI()
    }
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    if readerImmersiveEnabled {
      refreshImmersiveUI()
    }
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    if readerImmersiveEnabled {
      refreshImmersiveUI()
    }
  }

  private func refreshImmersiveUI() {
    setNeedsStatusBarAppearanceUpdate()
    setNeedsUpdateOfHomeIndicatorAutoHidden()
    setNeedsUpdateOfScreenEdgesDeferringSystemGestures()
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterPluginRegistrant {
  private var readerImmersiveEnabled = false
  private var storageBridge: StorageBridge?
  private var incomingBookBridge: IncomingBookBridge?
  private var readerAloudMediaBridge: ReaderAloudMediaBridge?
  private var applePurchaseSupportBridge: ApplePurchaseSupportBridge?
  private var sourceBrowserSessionBridge: SourceBrowserSessionBridge?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    pluginRegistrant = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func register(with registry: FlutterPluginRegistry) {
    GeneratedPluginRegistrant.register(with: registry)

    guard let messenger = registry.registrar(forPlugin: "ReaderUIBridge")?.messenger() else {
      NSLog("Reader bridge init failed: binaryMessenger unavailable")
      return
    }

    AuthCallbackBridge.shared.attach(messenger: messenger)

    let readerUIChannel = FlutterMethodChannel(
      name: "com.niki.xxread/reader_ui",
      binaryMessenger: messenger
    )
    readerUIChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case "setReaderImmersive":
        guard let args = call.arguments as? [String: Any],
              let enabled = args["enabled"] as? Bool else {
          result(
            FlutterError(
              code: "invalid_args",
              message: "expected {enabled: bool}",
              details: nil
            )
          )
          return
        }
        self?.readerImmersiveEnabled = enabled
        self?.applyReaderImmersiveIfPossible()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let readerStatusChannel = FlutterMethodChannel(
      name: "com.niki.xxread/reader_status",
      binaryMessenger: messenger
    )
    readerStatusChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case "getBatteryStatus":
        UIDevice.current.isBatteryMonitoringEnabled = true
        let level = UIDevice.current.batteryLevel
        guard level >= 0 else {
          result(nil)
          return
        }
        let state = UIDevice.current.batteryState
        result([
          "level": Int((level * 100).rounded()),
          "charging": state == .charging || state == .full,
        ])
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let diagnosticsChannel = FlutterMethodChannel(
      name: "com.niki.xxread/diagnostics",
      binaryMessenger: messenger
    )
    diagnosticsChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      guard call.method == "getResourceSnapshot" else {
        result(FlutterMethodNotImplemented)
        return
      }
      result(self.diagnosticsSnapshot())
    }

    let frameRateChannel = FlutterMethodChannel(
      name: "com.niki.xxread/fullscreen",
      binaryMessenger: messenger
    )
    frameRateChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case "setPowerSavingMode":
        guard let args = call.arguments as? [String: Any],
              let enabled = args["enabled"] as? Bool else {
          result(
            FlutterError(
              code: "invalid_args",
              message: "expected {enabled: bool}",
              details: nil
            )
          )
          return
        }
        IOSFrameRateController.setPowerSavingMode(enabled)
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    storageBridge = StorageBridge(messenger: messenger)
    incomingBookBridge = IncomingBookBridge(messenger: messenger)
    if readerAloudMediaBridge == nil {
      readerAloudMediaBridge = ReaderAloudMediaBridge(messenger: messenger)
    }
    if applePurchaseSupportBridge == nil {
      applePurchaseSupportBridge = ApplePurchaseSupportBridge(messenger: messenger)
    }
    if sourceBrowserSessionBridge == nil {
      sourceBrowserSessionBridge = SourceBrowserSessionBridge(
        messenger: messenger,
        presenter: window?.rootViewController
      )
    }

  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    applyReaderImmersiveIfPossible()
    IncomingBookInbox.shared.consumeSharedExtensionInboxIfConfigured()
  }

  private func diagnosticsSnapshot() -> [String: Any] {
    UIDevice.current.isBatteryMonitoringEnabled = true
    let level = UIDevice.current.batteryLevel
    let batteryState = UIDevice.current.batteryState
    let charging = batteryState == .charging || batteryState == .full

    var vmInfo = task_vm_info_data_t()
    var vmCount = mach_msg_type_number_t(
      MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<natural_t>.size
    )
    let vmResult = withUnsafeMutablePointer(to: &vmInfo) { pointer in
      pointer.withMemoryRebound(to: integer_t.self, capacity: Int(vmCount)) {
        task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &vmCount)
      }
    }

    var usage = rusage()
    let usageResult = getrusage(RUSAGE_SELF, &usage)
    let cpuMilliseconds: Int64? = usageResult == 0
      ? Int64(usage.ru_utime.tv_sec + usage.ru_stime.tv_sec) * 1_000
        + Int64(usage.ru_utime.tv_usec + usage.ru_stime.tv_usec) / 1_000
      : nil

    let appPowerSaving = UserDefaults.standard.bool(
      forKey: "flutter.power_saving_mode_v1"
    )
    let refreshRate = ProcessInfo.processInfo.isLowPowerModeEnabled || appPowerSaving
      ? 60
      : UIScreen.main.maximumFramesPerSecond

    let memoryValue: Any = vmResult == KERN_SUCCESS
      ? NSNumber(value: Int64(vmInfo.phys_footprint))
      : NSNull()
    let cpuValue: Any = cpuMilliseconds.map { NSNumber(value: $0) } ?? NSNull()
    let batteryValue: Any = level >= 0
      ? NSNumber(value: Int((level * 100).rounded()))
      : NSNull()
    let chargingValue: Any = batteryState == .unknown
      ? NSNull()
      : NSNumber(value: charging)

    return [
      "memory_bytes": memoryValue,
      "cpu_time_ms": cpuValue,
      "battery_level": batteryValue,
      "charging": chargingValue,
      "thermal_state": diagnosticsThermalState(),
      "device_model": diagnosticsDeviceModel(),
      "os_version": UIDevice.current.systemVersion,
      "display_refresh_rate_hz": Double(refreshRate),
    ]
  }

  private func diagnosticsThermalState() -> String {
    switch ProcessInfo.processInfo.thermalState {
    case .nominal: return "nominal"
    case .fair: return "fair"
    case .serious: return "serious"
    case .critical: return "critical"
    @unknown default: return "unknown"
    }
  }

  private func diagnosticsDeviceModel() -> String {
    var systemInfo = utsname()
    uname(&systemInfo)
    return withUnsafePointer(to: &systemInfo.machine) { pointer in
      pointer.withMemoryRebound(to: CChar.self, capacity: 1) {
        String(cString: $0)
      }
    }
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    if !IncomingBookInbox.uniqueSupportedFileURLs([url]).isEmpty {
      IncomingBookInbox.shared.accept(urls: [url], action: "open")
      return true
    }
    return super.application(app, open: url, options: options)
  }

  private func applyReaderImmersiveIfPossible() {
    guard let controller = currentReaderController() else { return }
    controller.setReaderImmersiveEnabled(readerImmersiveEnabled)
  }

  private func currentReaderController() -> ReaderFlutterViewController? {
    if #available(iOS 13.0, *) {
      for case let scene as UIWindowScene in UIApplication.shared.connectedScenes {
        let keyWindow = scene.windows.first(where: { $0.isKeyWindow }) ?? scene.windows.first
        if let found = findReaderController(in: keyWindow?.rootViewController) {
          return found
        }
      }
      return nil
    }
    return findReaderController(in: window?.rootViewController)
  }

  private func findReaderController(in viewController: UIViewController?) -> ReaderFlutterViewController? {
    guard let viewController else { return nil }
    if let reader = viewController as? ReaderFlutterViewController {
      return reader
    }
    if let presented = viewController.presentedViewController,
       let found = findReaderController(in: presented) {
      return found
    }
    if let nav = viewController as? UINavigationController {
      for vc in nav.viewControllers {
        if let found = findReaderController(in: vc) {
          return found
        }
      }
    }
    if let tab = viewController as? UITabBarController {
      for vc in tab.viewControllers ?? [] {
        if let found = findReaderController(in: vc) {
          return found
        }
      }
    }
    for child in viewController.children {
      if let found = findReaderController(in: child) {
        return found
      }
    }
    return nil
  }
}
