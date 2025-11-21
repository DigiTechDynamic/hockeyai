import Foundation

// MARK: - AI Schema Builder
/// Unified system for creating JSON schemas and parsing responses
/// Combines schema generation with type-safe parsing in a single source of truth
public protocol AISchemaConvertible: Codable {
    static var schemaDefinition: JSONSchema { get }
    /// Optional: Define critical fields that must exist in response
    static var criticalFields: [String]? { get }
}

// Default implementation - no critical fields by default
public extension AISchemaConvertible {
    static var criticalFields: [String]? { nil }
}

// MARK: - JSON Schema Types
public struct JSONSchema {
    public let type: SchemaType
    public let properties: [String: Property]?
    public let required: [String]?
    public let items: Property?
    public let description: String?
    
    public enum SchemaType: String {
        case object = "object"
        case array = "array"
        case string = "string"
        case number = "number"
        case integer = "integer"
        case boolean = "boolean"
    }
    
    public indirect enum Property {
        case simple(
            type: SchemaType,
            description: String? = nil,
            minimum: Double? = nil,
            maximum: Double? = nil,
            minLength: Int? = nil,
            maxLength: Int? = nil,
            enumValues: [String]? = nil
        )
        case object(
            properties: [String: Property],
            required: [String]? = nil,
            description: String? = nil
        )
        case array(
            items: Property,
            description: String? = nil
        )
    }
    
    /// Convert to dictionary for AI service
    /// - Parameter includeAdditionalProperties: Whether to include additionalProperties: false (required for OpenAI strict mode, incompatible with Gemini)
    func toDictionary(includeAdditionalProperties: Bool = false) -> [String: Any] {
        var dict: [String: Any] = ["type": type.rawValue]

        if let description = description {
            dict["description"] = description
        }

        if let properties = properties {
            dict["properties"] = properties.mapValues { $0.toDictionary(includeAdditionalProperties: includeAdditionalProperties) }
        }

        if let required = required {
            dict["required"] = required
        }

        if let items = items {
            dict["items"] = items.toDictionary(includeAdditionalProperties: includeAdditionalProperties)
        }

        // Required for OpenAI Structured Outputs (strict mode), but breaks Gemini
        if includeAdditionalProperties && type == .object {
            dict["additionalProperties"] = false
        }

        return dict
    }
}

extension JSONSchema.Property {
    func toDictionary(includeAdditionalProperties: Bool = false) -> [String: Any] {
        switch self {
        case .simple(let type, let description, let minimum, let maximum, let minLength, let maxLength, let enumValues):
            var dict: [String: Any] = ["type": type.rawValue]

            if let description = description {
                dict["description"] = description
            }
            if let minimum = minimum {
                dict["minimum"] = minimum
            }
            if let maximum = maximum {
                dict["maximum"] = maximum
            }
            if let minLength = minLength {
                dict["minLength"] = minLength
            }
            if let maxLength = maxLength {
                dict["maxLength"] = maxLength
            }
            if let enumValues = enumValues {
                dict["enum"] = enumValues
            }

            return dict

        case .object(let properties, let required, let description):
            var dict: [String: Any] = ["type": "object"]

            if let description = description {
                dict["description"] = description
            }
            dict["properties"] = properties.mapValues { $0.toDictionary(includeAdditionalProperties: includeAdditionalProperties) }
            if let required = required {
                dict["required"] = required
            }

            // Required for OpenAI Structured Outputs (strict mode), but breaks Gemini
            if includeAdditionalProperties {
                dict["additionalProperties"] = false
            }

            return dict

        case .array(let items, let description):
            var dict: [String: Any] = ["type": "array"]

            if let description = description {
                dict["description"] = description
            }
            dict["items"] = items.toDictionary(includeAdditionalProperties: includeAdditionalProperties)

            return dict
        }
    }
}

// MARK: - Schema Builder DSL
public struct SchemaBuilder {
    
    /// Create an object schema
    public static func object(
        properties: [String: JSONSchema.Property],
        required: [String]? = nil,
        description: String? = nil
    ) -> JSONSchema {
        JSONSchema(
            type: .object,
            properties: properties,
            required: required,
            items: nil,
            description: description
        )
    }
    
    /// Create a string property
    public static func string(
        description: String? = nil,
        minLength: Int? = nil,
        maxLength: Int? = nil,
        enumValues: [String]? = nil
    ) -> JSONSchema.Property {
        .simple(
            type: .string,
            description: description,
            minLength: minLength,
            maxLength: maxLength,
            enumValues: enumValues
        )
    }
    
    /// Create an integer property
    public static func integer(
        description: String? = nil,
        minimum: Int? = nil,
        maximum: Int? = nil
    ) -> JSONSchema.Property {
        .simple(
            type: .integer,
            description: description,
            minimum: minimum.map(Double.init),
            maximum: maximum.map(Double.init)
        )
    }
    
    /// Create a number property
    public static func number(
        description: String? = nil,
        minimum: Double? = nil,
        maximum: Double? = nil
    ) -> JSONSchema.Property {
        .simple(
            type: .number,
            description: description,
            minimum: minimum,
            maximum: maximum
        )
    }
    
    /// Create a nested object property
    public static func nestedObject(
        properties: [String: JSONSchema.Property],
        required: [String]? = nil,
        description: String? = nil
    ) -> JSONSchema.Property {
        .object(
            properties: properties,
            required: required,
            description: description
        )
    }
    
    /// Create an array property
    public static func array(
        items: JSONSchema.Property,
        description: String? = nil
    ) -> JSONSchema.Property {
        .array(
            items: items,
            description: description
        )
    }
}

// MARK: - Unified Response Handler
// (Removed unused AIResponseHandler and AIResponseError)
