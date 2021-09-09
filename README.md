Для решение проблемы неработающего JavaScript в Aitu нужно выполнить пустой скрипт при запуске `WKWebView` следущующим образом:
```
let userScript = WKUserScript(source: "", injectionTime: .atDocumentStart, forMainFrameOnly: true)
let userContentController = WKUserContentController()
userContentController.addUserScript(userScript)
let configuration = WKWebViewConfiguration()
configuration.userContentController = userContentController
webView = WKWebView(frame: .zero, configuration: configuration)
```

Пример того как это сделано есть в `Sample/AppDelegate.swift`