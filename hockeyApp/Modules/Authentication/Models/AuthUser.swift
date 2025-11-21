import Foundation

public struct AuthUser: Codable, Equatable {
    public let uid: String
    public let email: String?
    public let phoneNumber: String?
    public let displayName: String?
    public let photoURL: URL?
    public let isEmailVerified: Bool
    public let isAnonymous: Bool
    public let creationDate: Date?
    public let lastSignInDate: Date?
    public let providerID: String?
    
    public init(
        uid: String,
        email: String? = nil,
        phoneNumber: String? = nil,
        displayName: String? = nil,
        photoURL: URL? = nil,
        isEmailVerified: Bool = false,
        isAnonymous: Bool = false,
        creationDate: Date? = nil,
        lastSignInDate: Date? = nil,
        providerID: String? = nil
    ) {
        self.uid = uid
        self.email = email
        self.phoneNumber = phoneNumber
        self.displayName = displayName
        self.photoURL = photoURL
        self.isEmailVerified = isEmailVerified
        self.isAnonymous = isAnonymous
        self.creationDate = creationDate
        self.lastSignInDate = lastSignInDate
        self.providerID = providerID
    }
}

public enum AuthProvider: String, CaseIterable {
    case email = "password"
    case phone = "phone"
    case google = "google.com"
    case apple = "apple.com"
    case anonymous = "anonymous"
    
    public var displayName: String {
        switch self {
        case .email: return "Email"
        case .phone: return "Phone"
        case .google: return "Google"
        case .apple: return "Apple"
        case .anonymous: return "Anonymous"
        }
    }
}