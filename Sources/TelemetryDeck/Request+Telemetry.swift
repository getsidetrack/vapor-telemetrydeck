import Vapor

public extension Request {
    var telemetryDeck: TelemetryDeck {
        .init(application: application, request: self)
    }
    
    struct TelemetryDeck {
        public let application: Application
        public let request: Request
        
        public func send(_ signalType: String, floatValue: Double? = nil, additionalPayload: [String: String] = [:]) -> EventLoopFuture<ClientResponse> {
            // The XFF header may sometimes be comma-separated (this has been proven to be true on Google Cloud services).
            //
            // The header will include the client IP address first, followed by a number of proxy services such as load
            // balancers. These can change often and thus lead to the identifier changing for the same 'user' reporting
            // them multiple times.
            //
            // Source: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Forwarded-For
            //
            // To avoid this problem, we fetch only the first IP address within the header.
            let userIdentifier = request.headers.first(name: .xForwardedFor)?.components(separatedBy: ",").first ?? request.remoteAddress?.description
            
            return application.telemetryDeck.send(
                signalType,
                for: userIdentifier,
                floatValue: floatValue,
                additionalPayload: additionalPayload
            )
        }
        
        #if compiler(>=5.5) && canImport(_Concurrency)
        @discardableResult
        public func send(_ signalType: String, floatValue: Double? = nil, additionalPayload: [String: String] = [:]) async throws -> ClientResponse {
            try await send(signalType, floatValue: floatValue, additionalPayload: additionalPayload).get()
        }
        #endif
    }
}
