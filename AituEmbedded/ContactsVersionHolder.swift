final class ContactsVersionHolder {
    var contactsVersion: String = UUID().uuidString
    private let notificationCenter = NotificationCenter.default
    private var didChangeContactStoreToken: NSObjectProtocol?

    init() {
        didChangeContactStoreToken = notificationCenter.addObserver(
            forName: .CNContactStoreDidChange,
            object: nil,
            queue: .main,
            using: { [weak self] _ in
                self?.contactsVersion = UUID().uuidString
            })
    }

    deinit {
        if let x = didChangeContactStoreToken {
            notificationCenter.removeObserver(x)
        }
    }
}
