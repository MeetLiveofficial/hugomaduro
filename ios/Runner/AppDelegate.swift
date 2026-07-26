import Flutter
import GoogleMaps
import UIKit
import flutter_local_notifications
import AVFoundation
import app_links

@main
@objc class AppDelegate: FlutterAppDelegate {
    private var secureConfigured = false

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

        DispatchQueue.main.async { [weak self] in
            self?.setupScreenSecurityChannel()
            self?.enableScreenshotProtection()
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func setupScreenSecurityChannel() {
        guard let controller = window?.rootViewController as? FlutterViewController else {
            return
        }
        let channel = FlutterMethodChannel(
            name: "krimson/screen_security",
            binaryMessenger: controller.binaryMessenger
        )
        channel.setMethodCallHandler { [weak self] call, result in
            if call.method == "enableSecure" {
                self?.enableScreenshotProtection()
                result(nil)
            } else {
                result(FlutterMethodNotImplemented)
            }
        }
    }

    /// Capturas / grabaciones de pantalla en negro (UITextField secure).
    private func enableScreenshotProtection() {
        guard !secureConfigured, let window = self.window else { return }
        secureConfigured = true

        let field = UITextField()
        field.isSecureTextEntry = true
        field.isUserInteractionEnabled = false
        window.addSubview(field)
        field.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            field.centerXAnchor.constraint(equalTo: window.centerXAnchor),
            field.centerYAnchor.constraint(equalTo: window.centerYAnchor),
            field.widthAnchor.constraint(equalToConstant: 1),
            field.heightAnchor.constraint(equalToConstant: 1),
        ])

        window.layer.superlayer?.addSublayer(field.layer)
        if let last = field.layer.sublayers?.last {
            last.addSublayer(window.layer)
        }
    }
}
