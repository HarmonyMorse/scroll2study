import Foundation

enum ValidationError: LocalizedError {
    case invalidEmail
    case invalidPassword(String)

    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address"
        case .invalidPassword(let reason):
            return reason
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

    static func isValidPassword(_ password: String) -> (isValid: Bool, message: String?) {
        // Length check
        if password.count < 8 || password.count > 64 {
            return (false, "Password must be between 8 and 64 characters")
        }

        // Uppercase check
        if !password.contains(where: { $0.isUppercase }) {
            return (false, "Password must contain at least one uppercase letter")
        }

        // Lowercase check
        if !password.contains(where: { $0.isLowercase }) {
            return (false, "Password must contain at least one lowercase letter")
        }

        // Number check
        if !password.contains(where: { $0.isNumber }) {
            return (false, "Password must contain at least one number")
        }

        // Special character check
        let specialCharacters = CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")
        if password.rangeOfCharacter(from: specialCharacters) == nil {
            return (false, "Password must contain at least one special character")
        }

        return (true, nil)
    }

    static func validatePassword(_ password: String) throws {
        let validation = isValidPassword(password)
        if !validation.isValid {
            throw ValidationError.invalidPassword(validation.message ?? "Invalid password")
        }
    }
}
