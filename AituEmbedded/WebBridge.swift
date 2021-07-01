import WebKit

protocol WebBridgeController {
    var method: String { get }
    func receive(body: Any, from url: URL?, sender: WebBridgeSender)
}

final class MessageReceiver: NSObject, WKScriptMessageHandler {
    private let receive: (Any, URL?) -> Void

    init(receive: @escaping (Any, URL?) -> Void) {
        self.receive = receive
    }

    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        receive(message.body, message.webView?.url)
    }
}

public protocol WebBridgeSender {
    func send(reply: String)
}

public protocol WebBridgeRegistrator {
    func register(_ receiver: WKScriptMessageHandler, method: String)
}

public struct AituWebBridgeFormatter: WebBridgeSender {
    private let sender: (String) -> Void

    public init(sender: @escaping (String) -> Void) {
        self.sender = sender
    }

    public func send(reply: String) {
        let payloadPlace = "###payload###"
        let template = """
        window.dispatchEvent(new CustomEvent("aituEvents", {
            detail: \(payloadPlace)
        }))
        """
        let script = template.replacingOccurrences(of: payloadPlace, with: reply)
        sender(script)
    }
}

extension WKWebView: WebBridgeSender, WebBridgeRegistrator {
    public func send(reply: String) {
        DispatchQueue.main.async {
            self.evaluateJavaScript(reply, completionHandler: nil)
        }
    }

    public func register(_ receiver: WKScriptMessageHandler, method: String) {
        configuration.userContentController.add(receiver, name: method)
    }
}
