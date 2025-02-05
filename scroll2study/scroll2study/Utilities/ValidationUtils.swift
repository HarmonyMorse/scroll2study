import Foundation

enum ValidationError: LocalizedError {
    case invalidEmail

    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address"
        }
    }
}

struct ValidationUtils {
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegex =
            #"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"#

        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        let isValidFormat = emailPredicate.evaluate(with: email)

        // Additional validation rules
        let hasValidLength = email.count >= 3 && email.count <= 254
        let hasValidDomain = email.contains(".")

        return isValidFormat && hasValidLength && hasValidDomain
    }

    static func validateEmail(_ email: String) throws {
        guard isValidEmail(email) else {
            throw ValidationError.invalidEmail
        }
    }
}
