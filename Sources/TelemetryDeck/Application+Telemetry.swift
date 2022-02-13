// https://telemetrydeck.com/pages/ingestion-api-spec.html

import Foundation
import Vapor

public extension Application {
    var telemetryDeck: TelemetryDeck {
        .init(application: self)
    }
    
    struct TelemetryDeck {
        public let application: Application
        
        public func initialise(appID: String, baseURL: URL? = nil) {
            storage.appID = UUID(uuidString: appID)
            
            if let baseURL = baseURL {
                storage.baseURL = baseURL
            }
        }
        
        public func send(
            _ signalType: String,
            for clientUser: String? = nil,
            additionalPayload: [String: String] = [:]
        ) -> EventLoopFuture<ClientResponse> {
            guard let appID = storage.appID else {
                return application.eventLoopGroup.next()
                    .future(error: TelemetryDeckError.notInitialised)
            }
            
            var payload: [String: String] = [:]
            payload = payload.merging(defaultParameters, uniquingKeysWith: { _, last in last })
            payload = payload.merging(additionalPayload, uniquingKeysWith: { _, last in last })
            payload["telemetryClientVersion"] = "VaporTelemetryDeck 1.0.0"
            
            let encodedPayload: [String] = payload.map { key, value in
                key.replacingOccurrences(of: ":", with: "_") + ":" + value
            }
            
            let body = SignalPostBody(
                receivedAt: .init(),
                appID: appID,
                
                // The `clientUser` value will be equal to `sha256(clientUser)` or "vapor".
                clientUser: clientUser.map { $0.sha256() } ?? "vapor",
                
                // The `sessionID` is different for each server instance. It will change if the
                // server is restarted, or if a signal is sent from a different instance.
                sessionID: storage.sessionUUID.uuidString,
                
                type: signalType,
                payload: encodedPayload,
                
                // We will mark the signal as being in "test mode" if the environment is not production.
                isTestMode: application.environment.isRelease ? "false" : "true"
            )
            
            let uri = URI(string: storage.baseURL.absoluteString.finished(with: "/")
                .appending("api/v1/apps/\(appID.uuidString)/signals/multiple/"))
            
            do {
                let request = ClientRequest(
                    method: .POST,
                    url: uri,
                    headers: [ "Content-Type": "application/json" ],
                    body: try ByteBuffer(data: JSONEncoder.telemetryEncoder.encode([body]))
                )
                
                return application.client.send(request)
            } catch {
                return application.eventLoopGroup.next().future(error: error)
            }
        }
        
        #if compiler(>=5.5) && canImport(_Concurrency)
        @discardableResult
        public func send(
            _ signalType: String,
            for clientUser: String? = nil,
            additionalPayload: [String: String] = [:]
        ) async throws -> ClientResponse {
            try await send(signalType, for: clientUser, additionalPayload: additionalPayload).get()
        }
        #endif
        
        public var defaultParameters: [String: String] {
            get {
                storage.defaultParameters
            }
            nonmutating set {
                self.storage.defaultParameters = newValue
            }
        }
        
        var storage: Storage {
            if let existing = application.storage[Key.self] {
                return existing
            } else {
                let new = Storage()
                application.storage[Key.self] = new
                return new
            }
        }
        
        struct Key: StorageKey {
            typealias Value = Storage
        }
        
        final class Storage {
            var baseURL: URL
            var appID: UUID?
            var defaultParameters: [String: String] = [:]
            var sessionUUID: UUID = .init()

            init() {
                baseURL = URL(string: "https://nom.telemetrydeck.com/")!
                defaultParameters = [:]
            }
        }
    }
}

extension JSONEncoder {
    static var telemetryEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        encoder.dateEncodingStrategy = .formatted(dateFormatter)
        
        return encoder
    }()
}

extension JSONDecoder {
    static var telemetryDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        return decoder
    }()
}
