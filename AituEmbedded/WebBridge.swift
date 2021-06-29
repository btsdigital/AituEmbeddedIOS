import WebKit

protocol WebBridgeController {
    var method: String { get }
    func receive(body: Any, from url: URL?, within webView: WKWebView)
}

final class WebBridge {
    private let receivers: [MessageReceiver]

    init(_ webView: WKWebView, controllers: [WebBridgeController]) {
        receivers = controllers.map({ contoller in
            let receiver = MessageReceiver(receive: { body, url in
                contoller.receive(body: body, from: url, within: webView)
            })
            webView.configuration.userContentController.add(receiver, name: contoller.method)
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

extension WKWebView {
    func evaluateAituBridgeJavaScript(_ js: String) {
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
