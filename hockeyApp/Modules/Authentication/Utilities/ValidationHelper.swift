import Foundation

public struct ValidationHelper {
    
    // MARK: - Email Validation
    public static func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return predicate.evaluate(with: email)
    }
    
    // MARK: - Password Validation
    public struct PasswordValidation {
        public let isValid: Bool
        public let errors: [String]
        
        public static func validate(
            _ password: String,
            minimumLength: Int = 6,
            requireUppercase: Bool = false,
            requireLowercase: Bool = false,
            requireNumber: Bool = false,
            requireSpecialCharacter: Bool = false
        ) -> PasswordValidation {
            var errors: [String] = []
            
            if password.count < minimumLength {
                errors.append("Password must be at least \(minimumLength) characters")
            }
            
            if requireUppercase && !password.contains(where: { $0.isUppercase }) {
                errors.append("Password must contain at least one uppercase letter")
            }
            
            if requireLowercase && !password.contains(where: { $0.isLowercase }) {
                errors.append("Password must contain at least one lowercase letter")
            }
            
            if requireNumber && !password.contains(where: { $0.isNumber }) {
                errors.append("Password must contain at least one number")
            }
            
            if requireSpecialCharacter {
                let specialCharacters = CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")
                if password.rangeOfCharacter(from: specialCharacters) == nil {
                    errors.append("Password must contain at least one special character")
                }
            }
            
            return PasswordValidation(isValid: errors.isEmpty, errors: errors)
        }
    }
    
    /// Check if password meets strong password requirements
    public static func isStrongPassword(_ password: String) -> Bool {
        let validation = PasswordValidation.validate(
            password,
            minimumLength: AuthenticationContainer.shared.features.minimumPasswordLength,
            requireUppercase: true,
            requireLowercase: true,
            requireNumber: true,
            requireSpecialCharacter: false
        )
        return validation.isValid
    }
    
    // MARK: - Phone Number Validation
    public static func isValidPhoneNumber(_ phoneNumber: String) -> Bool {
        let phoneRegex = #"^\+[1-9]\d{1,14}$"#
        let predicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return predicate.evaluate(with: phoneNumber)
    }
    
    public static func formatPhoneNumber(_ phoneNumber: String, countryCode: String = "+1") -> String {
        let numbersOnly = phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        
        if numbersOnly.hasPrefix("1") && numbersOnly.count == 11 {
            return "+\(numbersOnly)"
        } else if numbersOnly.count == 10 {
            return "\(countryCode)\(numbersOnly)"
        } else if phoneNumber.hasPrefix("+") {
            return phoneNumber
        }
        
        return "\(countryCode)\(numbersOnly)"
    }
    
    // MARK: - Verification Code Validation
    public static func isValidVerificationCode(_ code: String, expectedLength: Int = 6) -> Bool {
        let numbersOnly = code.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        return numbersOnly.count == expectedLength
    }
    
    // MARK: - Name Validation
    public static func isValidName(_ name: String, minimumLength: Int = 2) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.count >= minimumLength
    }
    
    // MARK: - Field Sanitization
    public static func sanitizeEmail(_ email: String) -> String {
        return email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
    
    public static func sanitizePhoneNumber(_ phoneNumber: String) -> String {
        return phoneNumber.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
    }
}