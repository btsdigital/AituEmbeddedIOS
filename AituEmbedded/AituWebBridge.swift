import WebKit

public protocol AituWebBridgeDelegate {
    func getToken(completed: @escaping (Result<String, Error>) -> Void)
}

public final class AituWebBridge {
    enum Result {
        case success(Payload)
        case failure(Error)
    }

    enum Payload {
        case token(String)
        case empty
        case contacts([ContactBook.Contact])
    }

    enum Error: Swift.Error {
        case permissionDenied
        case unexpected(String)
    }

    public var delegate: AituWebBridgeDelegate?
    private let registrator: WebBridgeRegistrator
    private let sender: WebBridgeSender
    private let _start: () -> Void
    private var receivers: [MessageReceiver] = []

    init(registrator: WebBridgeRegistrator, sender: WebBridgeSender, start: @escaping () -> Void) {
        self.registrator = registrator
        self.sender = sender
        self._start = start
    }

    public func configure() {
        let getToken = Controller(method: "getKundelikAuthToken", handler: { [weak self] answer in
            if let delegate = self?.delegate {
                delegate.getToken(completed: { result in
                    switch result {
                    case .success(let token): answer(.success(.token(token)))
                    case .failure(let error): answer(.failure(.unexpected(error.localizedDescription)))
                    }
                })
            } else {
                answer(.failure(.unexpected("delegate is nil")))
            }
        })
        let openSettings = Controller(method: "openSettings", handler: { answer in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                DispatchQueue.main.async {
                    UIApplication.shared.open(url)
                    answer(.success(.empty))
                }
            } else {
                answer(.failure(.unexpected("can't create url for open setting")))
            }
        })
        let getContacts = Controller(method: "getContacts", handler: { answer in
            let book = ContactBook()
            book.requestAccess(handler: { result in
                switch result {
                case .success: answer(.success(.contacts(book.fetchContacts())))
                case .failure: answer(.failure(.permissionDenied))
                }
            })
        })

        let controllers = [getToken, openSettings, getContacts]
        receivers = controllers.map({ contoller -> MessageReceiver in
            let receiver = MessageReceiver(receive: { [sender] body, url in
                contoller.receive(body: body, from: url, sender: sender)
            })
            registrator.register(receiver, method: contoller.method)
            return receiver
        })
    }
}

extension AituWebBridge {
    public convenience init(_ webView: WKWebView, startURL: URL = URL(string: "https://kundelik.aitu.io/")!) {
        self.init(registrator: webView, sender: AituWebBridgeAdapter(sender: webView.send), start: {
            let requst = URLRequest(url: startURL)
            webView.load(requst)
        })
    }

    public func start() {
        _start()
    }
}
