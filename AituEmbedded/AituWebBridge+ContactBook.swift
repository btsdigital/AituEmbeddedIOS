import Contacts

extension AituWebBridge {
    final class ContactBook {
        struct Contact {
            let phone: String
            let firstName: String
            let lastName: String
        }
        private var isAllowContacts: Bool { CNContactStore.authorizationStatus(for: CNEntityType.contacts) == .authorized }

        func requestAccess(handler: @escaping (Result<Void, Error>) -> Void) {
            if isAllowContacts {
                handler(.success(()))
            } else {
                CNContactStore().requestAccess(for: CNEntityType.contacts, completionHandler: { isSuccess, error in
                    if isSuccess {
                        handler(.success(()))
                    } else {
                        handler(.failure(error ?? CNError(.authorizationDenied)))
                    }
                })
            }
        }

        func fetchContacts() -> [Contact] {
            guard isAllowContacts else {
                return []
            }
            let request = CNContactFetchRequest(keysToFetch: [CNContactGivenNameKey as CNKeyDescriptor,
                                                              CNContactFamilyNameKey as CNKeyDescriptor,
                                                              CNContactPhoneNumbersKey as CNKeyDescriptor])
            var contacts: [Contact] = []
            try? CNContactStore().enumerateContacts(with: request, usingBlock: { contact, _ in
                contacts += contact.phoneNumbers.compactMap({ phone in
                    Contact(phone: phone.phone, firstName: contact.givenName, lastName: contact.familyName)
                })
            })
            return contacts
        }
    }
}

extension CNLabeledValue where ValueType == CNPhoneNumber {
    fileprivate var phone: String {
        let characterSet = CharacterSet.decimalDigits.inverted
        var phoneNumber = value.stringValue.components(separatedBy: characterSet).joined()
        if phoneNumber.first == "8" {
            phoneNumber.remove(at: phoneNumber.startIndex)
            phoneNumber.insert("7", at: phoneNumber.startIndex)
        }
        return phoneNumber
    }
}
