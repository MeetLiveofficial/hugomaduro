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
            // No activar al arranque: el reparent de window.layer puede
            // dejar la UI a media pantalla / esquina en iOS recientes.
            // Se habilita solo vía canal cuando Dart lo pide, con el path seguro.
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

    /// Capturas / grabaciones en negro (capa segura del UITextField).
    /// Importante: se reparenta la capa del *Flutter view*, no de toda la
    /// `UIWindow` — reparentar `window.layer` rompe el layout (UI a 1/4).
    private func enableScreenshotProtection() {
        guard !secureConfigured else { return }
        guard let window = self.window,
              let flutterView = window.rootViewController?.view else { return }
        secureConfigured = true

        let field = UITextField()
        field.isSecureTextEntry = true
        field.isUserInteractionEnabled = false
        field.translatesAutoresizingMaskIntoConstraints = false
        flutterView.addSubview(field)
        NSLayoutConstraint.activate([
            field.centerXAnchor.constraint(equalTo: flutterView.centerXAnchor),
            field.centerYAnchor.constraint(equalTo: flutterView.centerYAnchor),
            field.widthAnchor.constraint(equalToConstant: 0),
            field.heightAnchor.constraint(equalToConstant: 0),
        ])

        // La capa "no capturable" suele ser la *primera* sublayer del field.
        flutterView.layer.superlayer?.addSublayer(field.layer)
        if let secureLayer = field.layer.sublayers?.first {
            secureLayer.addSublayer(flutterView.layer)
        }
    }
}
