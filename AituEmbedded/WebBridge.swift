import WebKit

protocol WebBridgeController {
    var method: String { get }
    func receive(body: Any, from url: URL?, sender: WebBridgeSender)
}

protocol WebBridgeSender {
    func send(reply: String)
}

final class WebBridge {
    struct Registrator {
        private let _register: (WKScriptMessageHandler, String) -> Void

        init(register: @escaping (WKScriptMessageHandler, String) -> Void) {
            _register = register
        }

        func register(_ receiver: WKScriptMessageHandler, method: String) {
            _register(receiver, method)
        }
    }
    private let receivers: [MessageReceiver]

    init(controllers: [WebBridgeController], registrator: Registrator, sender: WebBridgeSender) {
        receivers = controllers.map({ contoller in
            let receiver = MessageReceiver(receive: { body, url in
                contoller.receive(body: body, from: url, sender: sender)
            })
            registrator.register(receiver, method: contoller.method)
            return receiver
        })
    }
}

private final class MessageReceiver: NSObject, WKScriptMessageHandler {
    private let receive: (Any, URL?) -> Void

    init(receive: @escaping (Any, URL?) -> Void) {
        self.receive = receive
    }

    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        receive(message.body, message.webView?.url)
    }
}

extension WKWebView: WebBridgeSender {
    func send(reply js: String) {
        DispatchQueue.main.async {
            let payloadPlace = "###payload###"
            let template = """
            window.dispatchEvent(new CustomEvent("aituEvents", {
                detail: \(payloadPlace)
            }))
            """
            let script = template.replacingOccurrences(of: payloadPlace, with: js)
            self.evaluateJavaScript(script, completionHandler: nil)
        }
    }
}
