import Foundation

class AKConversions {
    static func formatPhoneNumber(phoneNumber: String, addPrefix: Bool) throws -> String {
        // Numbers allowed:
        // 1. 0981918689 (With prefix)
        // 2. 81918689 (Without prefix)
        var newPhone = ""
        // Strip all non-numeric characters.
        newPhone = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined(separator: "")
        // Make checks.
        // 1. Phone number must be al least 8 characters long.
        guard phoneNumber.characters.count >= GlobalConstants.AKMinPhoneNumberLength else {
            throw Exceptions.invalidLength("El número de teléfono debe tener por lo menos 8 dígitos.")
        }
        // Leave only the last 8 numbers.
        newPhone = newPhone.substring(from: newPhone.index(newPhone.endIndex, offsetBy: -GlobalConstants.AKMinPhoneNumberLength))
        // Add prefix.
        newPhone = addPrefix ? String(format: "09%@", newPhone) : newPhone
        
        return newPhone
    }
}
