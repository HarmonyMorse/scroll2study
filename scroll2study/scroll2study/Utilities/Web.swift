import Foundation

enum WebError: LocalizedError {
    case invalidResponse(statusCode: Int, message: String?)
    case invalidURL
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse(let statusCode, let message):
            if let message = message {
                return "Server error (\(statusCode)): \(message)"
            }
            return "Server returned error code: \(statusCode)"
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return error.localizedDescription
        }
    }
}

@propertyWrapper
struct Web {
    var wrappedValue: Web { self }

    func post(_ url: String, headers: [String: String], body: [String: Any]) async throws -> JSON {
        guard let url = URL(string: url) else {
            throw WebError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw WebError.invalidResponse(statusCode: 0, message: "Invalid response type")
            }

            // If not successful, try to parse error message from response
            if !(200...299).contains(httpResponse.statusCode) {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let error = json["error"] as? [String: Any],
                    let message = error["message"] as? String
                {
                    throw WebError.invalidResponse(
                        statusCode: httpResponse.statusCode, message: message)
                }
                throw WebError.invalidResponse(statusCode: httpResponse.statusCode, message: nil)
            }

            return try JSON(data: data)
        } catch let error as WebError {
            throw error
        } catch {
            throw WebError.networkError(error)
        }
    }

    subscript(dynamicMember keyPath: String) -> Any? {
        nil
    }
}

// Simple JSON wrapper for easy access to nested values
struct JSON {
    private var value: Any

    init(data: Data) throws {
        self.value = try JSONSerialization.jsonObject(with: data, options: [])
    }

    subscript(key: String) -> JSON {
        get {
            if let dict = value as? [String: Any] {
                return JSON(value: dict[key] ?? NSNull())
            }
            if let array = value as? [Any], let index = Int(key), index < array.count {
                return JSON(value: array[index])
            }
            return JSON(value: NSNull())
        }
    }

    var string: String? {
        value as? String
    }

    private init(value: Any) {
        self.value = value
    }
}

extension Dictionary {
    subscript(keyPath keyPath: String) -> Any? {
        let keys = keyPath.components(separatedBy: ".")
        return keys.reduce(self as Any) { result, key in
            guard let dict = result as? [String: Any] else { return nil }
            return dict[key]
        }
    }

    subscript(string keyPath: String) -> String? {
        self[keyPath: keyPath] as? String
    }
}
