import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let appIconChannelName = "prayday/app_icon"
  private var appIconChannel: FlutterMethodChannel?
  private var isAppIconChannelInstalled = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    installAppIconChannelIfNeeded()
    DispatchQueue.main.async { [weak self] in
      self?.installAppIconChannelIfNeeded()
    }
    return result
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    installAppIconChannelIfNeeded()
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    installAppIconChannelIfNeeded()
  }

  private func setDarkIconEnabled(_ enabled: Bool, result: @escaping FlutterResult) {
    guard UIApplication.shared.supportsAlternateIcons else {
      result(nil)
      return
    }
    let targetIconName: String? = enabled ? "AppIconDark" : nil
    if UIApplication.shared.alternateIconName == targetIconName {
      result(nil)
      return
    }
    UIApplication.shared.setAlternateIconName(targetIconName) { error in
      if let error {
        result(
          FlutterError(
            code: "icon_change_failed",
            message: error.localizedDescription,
            details: nil
          )
        )
        return
      }
      result(nil)
    }
  }

  private func installAppIconChannelIfNeeded() {
    if isAppIconChannelInstalled {
      return
    }
    guard let controller = resolveFlutterViewController() else {
      return
    }

    let channel = FlutterMethodChannel(
      name: appIconChannelName,
      binaryMessenger: controller.binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, flutterResult in
      guard call.method == "setDarkIconEnabled" else {
        flutterResult(FlutterMethodNotImplemented)
        return
      }
      guard
        let args = call.arguments as? [String: Any],
        let enabled = args["enabled"] as? Bool
      else {
        flutterResult(
          FlutterError(code: "bad_args", message: "Missing enabled argument", details: nil)
        )
        return
      }
      self?.setDarkIconEnabled(enabled, result: flutterResult)
    }
    appIconChannel = channel
    isAppIconChannelInstalled = true
  }

  private func resolveFlutterViewController() -> FlutterViewController? {
    if let controller = window?.rootViewController as? FlutterViewController {
      return controller
    }

    for scene in UIApplication.shared.connectedScenes {
      guard let windowScene = scene as? UIWindowScene else {
        continue
      }
      if let keyWindow = windowScene.windows.first(where: \.isKeyWindow),
         let controller = keyWindow.rootViewController as? FlutterViewController {
        return controller
      }
      if let controller = windowScene.windows.first?.rootViewController as? FlutterViewController {
        return controller
      }
    }
    return nil
  }
}
