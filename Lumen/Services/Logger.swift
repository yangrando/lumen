import Foundation

// MARK: - Logger Service

class Logger {
    static let shared = Logger()
    
    // Log levels
    enum LogLevel: String {
        case debug = "🔵 DEBUG"
        case info = "🟢 INFO"
        case warning = "🟡 WARNING"
        case error = "🔴 ERROR"
        case success = "✅ SUCCESS"
    }
    
    private init() {}
    
    // MARK: - Logging Methods
    
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, file: file, function: function, line: line)
    }
    
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, file: file, function: function, line: line)
    }
    
    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, file: file, function: function, line: line)
    }
    
    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, file: file, function: function, line: line)
    }
    
    func success(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .success, file: file, function: function, line: line)
    }
    
    // MARK: - Private Logging Method
    
    private func log(
        _ message: String,
        level: LogLevel,
        file: String,
        function: String,
        line: Int
    ) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let timestamp = getCurrentTimestamp()
        
        let logMessage = """
        \(level.rawValue) [\(timestamp)] \(fileName):\(line) - \(function)
        └─ \(message)
        """
        
        print(logMessage)
    }
    
    // MARK: - Utility Methods
    
    private func getCurrentTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: Date())
    }
    
    // MARK: - Log API Response
    
    func logAPIRequest(
        url: String,
        method: String = "GET",
        headers: [String: String]? = nil,
        body: String? = nil
    ) {
        var message = "API Request: \(method) \(url)"
        if let headers = headers {
            message += "\nHeaders: \(headers)"
        }
        if let body = body {
            message += "\nBody: \(body)"
        }
        info(message)
    }
    
    func logAPIResponse(
        statusCode: Int,
        headers: [AnyHashable: Any]? = nil,
        body: String? = nil
    ) {
        let statusEmoji = (200...299).contains(statusCode) ? "✅" : "❌"
        var message = "API Response: \(statusEmoji) Status \(statusCode)"
        if let headers = headers {
            message += "\nHeaders: \(headers)"
        }
        if let body = body {
            message += "\nBody: \(body)"
        }
        
        if (200...299).contains(statusCode) {
            success(message)
        } else {
            error(message)
        }
    }
    
    func logAPIError(_ error: Error, context: String = "") {
        var message = "API Error"
        if !context.isEmpty {
            message += " (\(context))"
        }
        message += ": \(error.localizedDescription)"
        self.error(message)
    }
}

// MARK: - Convenience Extension

extension Logger {
    /// Log a JSON object for debugging
    func logJSON(_ object: Any, title: String = "JSON") {
        if let data = try? JSONSerialization.data(withJSONObject: object, options: .prettyPrinted),
           let jsonString = String(data: data, encoding: .utf8) {
            info("\(title):\n\(jsonString)")
        }
    }
    
    /// Log a decodable object
    func logDecodable<T: Encodable>(_ object: T, title: String = "Object") {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(object)
            if let jsonString = String(data: data, encoding: .utf8) {
                info("\(title):\n\(jsonString)")
            }
        } catch {
            self.error("Failed to encode object: \(error.localizedDescription)")
        }
    }
}
