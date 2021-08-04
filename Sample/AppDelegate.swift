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

final class AituViewController: UIViewController {
    enum DemoError: Error {
        case something
    }
    private let webView = WKWebView()
    private var bridge: AituWebBridge?

    override func viewDidLoad() {
        super.viewDidLoad()

        // для теста элементов
        bridge = AituWebBridge(webView, startURL: URL(string: "https://astanajs.kz/test-kundelik")!)

        // для интеграции в кунделик используй дефолт
//        bridge = AituWebBridge(webView)

        bridge?.delegate = self
        bridge?.configure()

        webView.frame = view.bounds
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(webView)

        bridge?.start()
    }
}

extension AituViewController: AituWebBridgeDelegate {
    func getToken(completed: @escaping (Result<String, AituWebBridge.Error>) -> Void) {
//        completed(.failure(.unexpected("something")))
        completed(.success("kz123"))
    }

    func getUserInfo(completed: @escaping (Result<User, AituWebBridge.Error>) -> Void) {
        let user = User(id: "1", role: .student(classID: "class-1"))
        completed(.success(user))
    }

    func notify(about event: Event) {
        print(event)
    }
}
