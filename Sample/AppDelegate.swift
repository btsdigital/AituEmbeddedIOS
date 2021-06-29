import UIKit
import WebKit
import AituEmbedded

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow()
        window?.rootViewController = AituViewController()
        window?.rootViewController?.view.backgroundColor = .green
        window?.makeKeyAndVisible()
        return true
    }
}

final class AituViewController: UIViewController, AituWebBridgeDelegate {
    enum DemoError: Error {
        case something
    }
    private let webView = WKWebView()
    private var bridge: AituWebBridge?

    override func viewDidLoad() {
        super.viewDidLoad()
        bridge = AituWebBridge(webView: webView)
        bridge?.delegate = self
        bridge?.start()

        webView.frame = view.bounds
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(webView)

        let requst = URLRequest(url: URL(string: "https://astanajs.kz/test-kundelik")!)
        webView.load(requst)
    }

    func getToken(completed: @escaping (Result<String, Error>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
//            completed(.failure(DemoError.something))
            completed(.success("kz123"))
        })
    }
}
