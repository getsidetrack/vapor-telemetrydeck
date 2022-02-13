import Vapor

extension Request {
    public var telemetryDeck: TelemetryDeck {
        .init(application: application, request: self)
    }
    
    public struct TelemetryDeck {
        public let application: Application
        public let request: Request
        
        public func send(_ signalType: String, additionalPayload: [String: String] = [:]) async throws {
            let userIdentifier = request.headers.first(name: .xForwardedFor) ?? request.remoteAddress?.description
            
            try await application.telemetryDeck.send(
                signalType,
                for: userIdentifier,
                additionalPayload: additionalPayload
            )
        }
    }
}
