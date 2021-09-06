import Foundation

extension AituWebBridge {
    struct Controller: WebBridgeController {
        let method: String
        private let handler: ([String: Any], @escaping (Result) -> Void) -> Void
        private let coder = Coder()

        init(method: String, handler: @escaping ([String: Any], @escaping (Result) -> Void) -> Void) {
            self.method = method
            self.handler = handler
        }

        func receive(body: Any, from url: URL?, sender: WebBridgeSender) {
            guard let body = body as? [String: Any], let reqID = coder.decodeID(body) else {
                let reason = "can't parse request id or body type not [String: Any]"
                sender.send(reply: coder.encode(.failure(.unexpected(reason)), requestID: ""))
                return
            }
            handler(body, { [coder] result in
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
            if let encoded = encode(result) {
                return """
                {
                    requestId: "\(requestID)",
                    \(encoded)
                }
                """
            } else {
                return """
                {
                    requestId: "\(requestID)"
                }
                """
            }
        }

        private func encode(_ result: Result) -> String? {
            switch result {
            case .success(let payload): return encode(payload)
            case .failure(let error): return encode(error)
            }
        }

        private func encode(_ payload: Payload) -> String? {
            switch payload {
            case .token(let token):
                return """
                data: {
                    "authToken": "\(token)"
                }
                """
            case .bool(let bool):
                return "data: \(bool)"
            case .empty:
                return nil
            case .contacts(let contacts):
                return """
                "data": {
                    "contacts": \(encode(contacts))
                }
                """
            case .user(let user):
                var r = """
                "data": {
                    "kundelikUserId": "\(user.id)",
                """
                switch user.role {
                case .teacher:
                    r += """
                    "role": "EduStaff"
                }
                """
                case .parent:
                    r += """
                    "role": "EduParent"
                }
                """
                case .student(let classID):
                    r += """
                    "role": "EduStudent",
                    "classId": "\(classID)"
                }
                """
                }
                return r
            case .contactsVersion(let version):
                return """
                "data": "\(version)"
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
