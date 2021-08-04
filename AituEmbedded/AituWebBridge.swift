import WebKit

public protocol AituWebBridgeDelegate {
    func getToken(completed: @escaping (Result<String, AituWebBridge.Error>) -> Void)
    func getUserInfo(completed: @escaping (Result<User, AituWebBridge.Error>) -> Void)
    func notify(about event: Event)
}

public enum Event: String {
    case newMessage = "new_message"
}

public struct User {
    public enum Role {
        case parent
        case teacher
        case student(classID: String)
    }
    public let id: String
    public let role: Role

    public init(id: String, role: Role) {
        self.id = id
        self.role = role
    }
}

public final class AituWebBridge {
    enum Result {
        case success(Payload)
        case failure(Error)
    }

    enum Payload {
        case empty
        case token(String)
        case bool(Bool)
        case contacts([ContactBook.Contact])
        case user(User)
    }

    public enum Error: Swift.Error {
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
        let getToken = Controller(method: "getKundelikAuthToken", handler: { [weak self] _, answer in
            guard let delegate = self?.delegate else {
                answer(.failure(.unexpected("delegate is nil")))
                return
            }
            delegate.getToken(completed: { result in
                switch result {
                case .success(let token): answer(.success(.token(token)))
                case .failure(let error): answer(.failure(error))
                }
            })
        })
        let openSettings = Controller(method: "openSettings", handler: { _, answer in
            guard let url = URL(string: UIApplication.openSettingsURLString) else {
                answer(.failure(.unexpected("can't create url for open setting")))
                return
            }
            DispatchQueue.main.async {
                UIApplication.shared.open(url)
                answer(.success(.bool(true)))
            }
        })
        let getContacts = Controller(method: "getContacts", handler: { _, answer in
            let book = ContactBook()
            book.requestAccess(handler: { result in
                switch result {
                case .success: answer(.success(.contacts(book.fetchContacts())))
                case .failure: answer(.failure(.permissionDenied))
                }
            })
        })
        let newEvent = Controller(method: "showNewMessengerEvent", handler: { [weak self] body, answer in
            guard let delegate = self?.delegate else {
                answer(.failure(.unexpected("delegate is nil")))
                return
            }
            guard let x = body["data"] as? [String: String],
                  let type = x["eventType"],
                  let event = Event(rawValue: type) else {
                answer(.failure(.unexpected("invalid event type")))
                return
            }
            delegate.notify(about: event)
            answer(.success(.empty))
        })
        let getUser = Controller(method: "getKundelikUserInfo", handler: { [weak self] _, answer in
            guard let delegate = self?.delegate else {
                answer(.failure(.unexpected("delegate is nil")))
                return
            }
            delegate.getUserInfo(completed: { result in
                switch result {
                case .success(let user): answer(.success(.user(user)))
                case .failure(let error): answer(.failure(error))
                }
            })
        })

        let controllers = [getToken, openSettings, getContacts, newEvent, getUser]
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
