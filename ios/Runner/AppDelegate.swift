import Flutter
import GoogleMaps
import UIKit
import flutter_local_notifications
import AVFoundation
import app_links

@main
@objc class AppDelegate: FlutterAppDelegate {
    private let screenGuard = ScreenCaptureGuard()

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
            GeneratedPluginRegistrant.register(with: registry)
        }

        UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
        GMSServices.provideAPIKey("____ GOOGLE API ______")
        GeneratedPluginRegistrant.register(with: self)
        if let url = AppLinks.shared.getLink(launchOptions: launchOptions) {
            AppLinks.shared.handleLink(url: url)
        }

        let launched = super.application(application, didFinishLaunchingWithOptions: launchOptions)
        screenGuard.start(appDelegate: self)
        return launched
    }

    override func applicationDidBecomeActive(_ application: UIApplication) {
        super.applicationDidBecomeActive(application)
        screenGuard.applicationBecameActive()
    }

    override func applicationWillResignActive(_ application: UIApplication) {
        screenGuard.applicationWillResignActive()
        super.applicationWillResignActive(application)
    }

    override func applicationWillEnterForeground(_ application: UIApplication) {
        super.applicationWillEnterForeground(application)
        screenGuard.applicationBecameActive()
    }
}

/// Bloquea capturas / grabación / snapshot del app switcher en iOS.
/// Android usa FLAG_SECURE; aquí el equivalente es el contenedor seguro de UITextField.
private final class ScreenCaptureGuard {
    private weak var appDelegate: FlutterAppDelegate?
    private var secureField: UITextField?
    private var privacyCover: UIView?
    private var retryCount = 0
    private var channelInstalled = false
    private var observersInstalled = false

    func start(appDelegate: FlutterAppDelegate) {
        self.appDelegate = appDelegate
        installObservers()
        DispatchQueue.main.async { [weak self] in
            self?.installChannel()
            self?.enableProtection()
        }
    }

    func applicationBecameActive() {
        hidePrivacyCoverIfAllowed()
        enableProtection()
        // Re-armar el flag seguro: iOS lo pierde al volver de background.
        if let field = secureField {
            field.isSecureTextEntry = false
            field.isSecureTextEntry = true
        }
    }

    func applicationWillResignActive() {
        showPrivacyCover()
    }

    private func installObservers() {
        guard !observersInstalled else { return }
        observersInstalled = true

        NotificationCenter.default.addObserver(
            forName: UIScreen.capturedDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateRecordingCover()
        }

        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.applicationBecameActive()
        }
    }

    private func installChannel() {
        guard !channelInstalled else { return }
        guard let controller = flutterController() else {
            scheduleRetry()
            return
        }
        let channel = FlutterMethodChannel(
            name: "krimson/screen_security",
            binaryMessenger: controller.binaryMessenger
        )
        channel.setMethodCallHandler { [weak self] call, result in
            if call.method == "enableSecure" {
                self?.enableProtection()
                result(true)
            } else {
                result(FlutterMethodNotImplemented)
            }
        }
        channelInstalled = true
    }

    private func enableProtection() {
        installChannel()
        guard let window = keyWindow(),
              let rootView = window.rootViewController?.view else {
            scheduleRetry()
            return
        }

        if isProtected(rootView: rootView, window: window) {
            secureField?.isSecureTextEntry = true
            updateRecordingCover()
            return
        }

        // 1) Layer trick (menos invasivo; teclado / LiveKit intactos).
        if applyLayerTrick(window: window) {
            retryCount = 0
            updateRecordingCover()
            return
        }

        // 2) Canvas del UITextField si el superlayer aún no existe.
        if wrapInSecureCanvas(rootView: rootView, window: window) {
            retryCount = 0
            updateRecordingCover()
            return
        }

        scheduleRetry()
    }

    /// Envuelve la vista Flutter en el canvas interno del UITextField seguro.
    /// Es el método más estable en iOS 15–18 (no depende de superlayer).
    @discardableResult
    private func wrapInSecureCanvas(rootView: UIView, window: UIWindow) -> Bool {
        let field = makeSecureField()
        window.insertSubview(field, at: 0)
        field.frame = CGRect(x: 0, y: 0, width: 1, height: 1)
        field.layoutIfNeeded()

        guard let canvas = field.subviews.first else {
            field.removeFromSuperview()
            return false
        }

        canvas.isUserInteractionEnabled = true
        let parent = rootView.superview ?? window
        rootView.removeFromSuperview()
        parent.addSubview(canvas)
        canvas.frame = parent.bounds
        canvas.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        canvas.addSubview(rootView)
        rootView.frame = canvas.bounds
        rootView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        secureField = field
        DispatchQueue.main.async {
            field.isSecureTextEntry = false
            field.isSecureTextEntry = true
        }
        return true
    }

    /// Fallback: reparenta window.layer dentro del layer seguro (iOS 13–18).
    @discardableResult
    private func applyLayerTrick(window: UIWindow) -> Bool {
        guard let screenLayer = window.layer.superlayer else { return false }

        let field = makeSecureField()
        window.addSubview(field)
        field.frame = .zero
        field.layoutIfNeeded()
        screenLayer.addSublayer(field.layer)

        let secureSublayer: CALayer?
        if #available(iOS 17.0, *) {
            secureSublayer = field.layer.sublayers?.last ?? field.layer.sublayers?.first
        } else {
            secureSublayer = field.layer.sublayers?.first ?? field.layer.sublayers?.last
        }

        guard let secureSublayer else {
            field.removeFromSuperview()
            field.layer.removeFromSuperlayer()
            return false
        }

        secureSublayer.addSublayer(window.layer)
        secureField = field
        return true
    }

    private func makeSecureField() -> UITextField {
        let field = UITextField()
        field.isSecureTextEntry = true
        field.isUserInteractionEnabled = false
        field.backgroundColor = .clear
        if #available(iOS 13.0, *) {
            field.overrideUserInterfaceStyle = .light
        }
        return field
    }

    private func isProtected(rootView: UIView, window: UIWindow) -> Bool {
        guard let field = secureField else { return false }

        let parentName = String(describing: type(of: rootView.superview ?? UIView()))
        if parentName.contains("CanvasView") || parentName.contains("TextLayout") {
            return true
        }

        var layer: CALayer? = window.layer.superlayer
        while let current = layer {
            if current === field.layer {
                return true
            }
            layer = current.superlayer
        }
        return false
    }

    private func scheduleRetry() {
        retryCount += 1
        guard retryCount <= 40 else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.enableProtection()
        }
    }

    private func updateRecordingCover() {
        if UIScreen.main.isCaptured {
            showPrivacyCover()
        } else if UIApplication.shared.applicationState == .active {
            hidePrivacyCoverIfAllowed()
        }
    }

    private func showPrivacyCover() {
        guard let window = keyWindow() else { return }
        if privacyCover == nil {
            let cover = UIView(frame: window.bounds)
            cover.backgroundColor = .black
            cover.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            cover.isUserInteractionEnabled = true
            privacyCover = cover
        }
        guard let cover = privacyCover else { return }
        if cover.superview !== window {
            window.addSubview(cover)
        }
        cover.frame = window.bounds
        window.bringSubviewToFront(cover)
        cover.isHidden = false
    }

    private func hidePrivacyCoverIfAllowed() {
        if UIScreen.main.isCaptured { return }
        privacyCover?.isHidden = true
        privacyCover?.removeFromSuperview()
    }

    private func flutterController() -> FlutterViewController? {
        var queue: [UIViewController] = []
        if let root = keyWindow()?.rootViewController {
            queue.append(root)
        }
        while !queue.isEmpty {
            let current = queue.removeFirst()
            if let flutter = current as? FlutterViewController {
                return flutter
            }
            queue.append(contentsOf: current.children)
            if let presented = current.presentedViewController {
                queue.append(presented)
            }
            if let nav = current as? UINavigationController {
                queue.append(contentsOf: nav.viewControllers)
            }
        }
        return nil
    }

    private func keyWindow() -> UIWindow? {
        if let window = appDelegate?.window,
           !window.isHidden,
           window.rootViewController != nil {
            return window
        }
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter {
                $0.activationState == .foregroundActive
                    || $0.activationState == .foregroundInactive
            }
            .flatMap(\.windows)
        return windows.first(where: \.isKeyWindow)
            ?? windows.first(where: { !$0.isHidden && $0.rootViewController != nil })
    }
}
