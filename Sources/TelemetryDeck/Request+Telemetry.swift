import Vapor

public extension Request {
    var telemetryDeck: TelemetryDeck {
        .init(application: application, request: self)
    }
    
    struct TelemetryDeck {
        public let application: Application
        public let request: Request
        
        public func send(_ signalType: String, additionalPayload: [String: String] = [:]) -> EventLoopFuture<ClientResponse> {
            let userIdentifier = request.headers.first(name: .xForwardedFor) ?? request.remoteAddress?.description
            
            return application.telemetryDeck.send(
                signalType,
                for: userIdentifier,
                additionalPayload: additionalPayload
            )
        }
        
        #if compiler(>=5.5) && canImport(_Concurrency)
        @discardableResult
        public func send(_ signalType: String, additionalPayload: [String: String] = [:]) async throws -> ClientResponse {
            try await send(signalType, additionalPayload: additionalPayload).get()
        }
        #endif
    }
}
