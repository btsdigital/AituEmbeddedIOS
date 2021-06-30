import WebKit

public protocol AituWebBridgeDelegate {
    func getToken(completed: @escaping (Result<String, Error>) -> Void)
}

public final class AituWebBridge {
    private enum Result {
        case success(Payload)
        case failure(Error)
    }

    private enum Payload {
        case token(String)
        case empty
        case contacts([ContactBook.Contact])
    }

    private enum Error: Swift.Error {
        case permissionDenied
        case unexpected(String)
    }

    public var delegate: AituWebBridgeDelegate?
    private let webView: WKWebView
    private var bridge: WebBridge?

    public init(webView: WKWebView = WKWebView()) {
        self.webView = webView
    }

    public func start() {
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
        bridge = WebBridge(webView, controllers: [getToken, openSettings, getContacts], sender: webView)
    }
}

extension AituWebBridge {
    private struct Controller: WebBridgeController {
        let method: String
        private let handler: (@escaping (Result) -> Void) -> Void
        private let coder = Coder()

        init(method: String, handler: @escaping (@escaping (Result) -> Void) -> Void) {
            self.method = method
            self.handler = handler
        }

        func receive(body: Any, from url: URL?, sender: WebBridgeSender) {
            guard let body = body as? [String: Any], let reqID = coder.decodeID(body) else {
                let reason = "can't parse request id or body type not [String: Any]"
                sender.send(reply: coder.encode(.failure(.unexpected(reason)), requestID: ""))
                return
            }
            handler({ result in
                switch result {
                case .success(let x): sender.send(reply: coder.encode(.success(x), requestID: reqID))
                case .failure(let error): sender.send(reply: coder.encode(.failure(error), requestID: reqID))
                }
            })
        }
    }

    private struct Coder {
        func decodeID(_ dictionary: [String: Any]) -> String? {
            let key = "requestId"
            if let id = dictionary[key] as? Int {
                return String(id)
            } else {
                return dictionary[key] as? String
            }
        }

        func encode(_ result: Result, requestID: String) -> String {
            let reply: String
            switch result {
            case .success(let payload):
                reply = encode(payload)
            case .failure(let error):
                reply = encode(error)
            }
            return """
            {
                requestId: "\(requestID)",
                \(reply)
            }
            """
        }

        func encode(_ payload: Payload) -> String {
            switch payload {
            case .token(let token):
                return """
                data: {
                    "authToken": "\(token)"
                }
                """
            case .empty:
                return "data: true"
            case .contacts(let contacts):
                return """
                "data": {
                    "contacts": \(encode(contacts))
                }
                """
            }
        }

        func encode(_ contacts: [ContactBook.Contact]) -> String {
            let xs = contacts.map({ contact in
                """
                {
                    "first_name": "\(contact.firstName)",
                    "last_name": "\(contact.lastName)",
                    "phone": "\(contact.phone)"
                }
                """
            })
            return "[\(xs.joined(separator: ","))]"
        }

        func encode(_ error: Error) -> String {
            switch error {
            case .permissionDenied:
                return """
                "error": {
                    "code": "PERMISSION_DENIED",
                    "msg": ""
                }
                """
            case .unexpected(let description):
                return """
                "error": {
                    "code": "UNEXPECTED",
                    "msg": "\(description)"
                }
                """
            }
        }
    }
}
