import Foundation

extension AituWebBridge {
    struct Controller: WebBridgeController {
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
            return """
            {
                requestId: "\(requestID)",
                \(encode(result))
            }
            """
        }

        private func encode(_ result: Result) -> String {
            switch result {
            case .success(let payload): return encode(payload)
            case .failure(let error): return encode(error)
            }
        }

        private func encode(_ payload: Payload) -> String {
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

        private func encode(_ contacts: [ContactBook.Contact]) -> String {
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

        private func encode(_ error: Error) -> String {
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
