import Foundation
@testable import TelemetryDeck
import XCTest
import XCTVapor

class TelemetryDeckTests: XCTestCase {
    let testID = "08436552-7639-4E0B-97BA-2DF8E1F7D203"
    
    // MARK: - Setup
    
    func testDefaultSetup() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        
        app.telemetryDeck.initialise(appID: testID)
        
        XCTAssertEqual(app.telemetryDeck.storage.appID?.uuidString, testID)
        XCTAssertEqual(app.telemetryDeck.storage.baseURL.absoluteString, "https://nom.telemetrydeck.com/")
    }
    
    func testSetupWithCustomURL() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        
        app.telemetryDeck.initialise(appID: testID, baseURL: URL(string: "https://example.com/"))
        
        XCTAssertEqual(app.telemetryDeck.storage.appID?.uuidString, testID)
        XCTAssertEqual(app.telemetryDeck.storage.baseURL.absoluteString, "https://example.com/")
    }
    
    // MARK: - System Signal
    
    func testSystemSignal() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        
        app.clients.use(.custom)
        
        app.telemetryDeck.initialise(appID: testID)
        _ = try app.telemetryDeck.send("signal").wait()
        
        XCTAssertEqual(app.customClient.requests.count, 1)
        
        let request = try XCTUnwrap(app.customClient.requests.first)
        XCTAssertEqual(request.url.string, "https://nom.telemetrydeck.com/api/v1/apps/\(testID)/signals/multiple/")
        
        let signal = try getFirstSignal(from: app)
        XCTAssertEqual(signal.appID.uuidString, testID)
        XCTAssertEqual(signal.payload, ["telemetryClientVersion:VaporTelemetryDeck 1.0.0"])
        XCTAssertEqual(signal.isTestMode, "true")
        XCTAssertEqual(signal.clientUser, "vapor")
        XCTAssertEqual(signal.type, "signal")
    }
    
    // MARK: - Request Signal
    
    func testRequestSignal() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        
        app.clients.use(.custom)
        
        app.telemetryDeck.initialise(appID: testID)
        
        app.get("test") { request -> EventLoopFuture<String> in
            request.telemetryDeck.send("signal").map { _ in
                "success"
            }
        }
        
        try app.testable().test(.GET, "test", headers: ["X-Forwarded-For": "localhost"])
        
        XCTAssertEqual(app.customClient.requests.count, 1)
        
        let request = try XCTUnwrap(app.customClient.requests.first)
        XCTAssertEqual(request.url.string, "https://nom.telemetrydeck.com/api/v1/apps/\(testID)/signals/multiple/")
        
        let signal = try getFirstSignal(from: app)
        XCTAssertEqual(signal.appID.uuidString, testID)
        XCTAssertEqual(signal.payload, ["telemetryClientVersion:VaporTelemetryDeck 1.0.0"])
        XCTAssertEqual(signal.isTestMode, "true")
        XCTAssertEqual(signal.clientUser, "49960de5880e8c687434170f6476605b8fe4aeb9a28632c7995cf3ba831d9763")
        XCTAssertEqual(signal.type, "signal")
    }
    
    // MARK: - Properties
    
    func testProperties() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        
        app.clients.use(.custom)
        
        app.telemetryDeck.initialise(appID: testID)
        
        app.telemetryDeck.defaultParameters = [
            "key1": "value1",
        ]
        
        _ = try app.telemetryDeck.send("signal", additionalPayload: [
            "key2": "value2",
        ]).wait()
        
        let signal = try getFirstSignal(from: app)
        XCTAssertEqual(signal.payload.sorted(), [
            "key1:value1",
            "key2:value2",
            "telemetryClientVersion:VaporTelemetryDeck 1.0.0",
        ])
    }
    
    func testPropertiesPriority() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        
        app.clients.use(.custom)
        
        app.telemetryDeck.initialise(appID: testID)
        
        app.telemetryDeck.defaultParameters = [
            "default": "true",
            "telemetryClientVersion": "default",
        ]
        
        _ = try app.telemetryDeck.send("signal", additionalPayload: [
            "function": "true",
            "telemetryClientVersion": "function",
        ]).wait()
        
        let signal = try getFirstSignal(from: app)
        XCTAssertEqual(signal.payload.sorted(), [
            "default:true",
            "function:true",
            "telemetryClientVersion:VaporTelemetryDeck 1.0.0",
        ])
    }
    
    // MARK: - Helpers
    
    func getFirstSignal(from app: Application) throws -> SignalPostBody {
        let body = try XCTUnwrap(app.customClient.requests.first?.body)
        let signals = try JSONDecoder.telemetryDecoder.decode([SignalPostBody].self, from: body)
        return try XCTUnwrap(signals.first)
    }
}
