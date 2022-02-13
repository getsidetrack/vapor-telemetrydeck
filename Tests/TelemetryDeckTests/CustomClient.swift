import XCTVapor

final class CustomClient: Client {
    var eventLoop: EventLoop {
        EmbeddedEventLoop()
    }

    var requests: [ClientRequest]

    init() {
        requests = []
    }

    func send(_ request: ClientRequest) -> EventLoopFuture<ClientResponse> {
        requests.append(request)
        return eventLoop.makeSucceededFuture(ClientResponse())
    }

    func delegating(to _: EventLoop) -> Client {
        self
    }
}

extension Application {
    struct CustomClientKey: StorageKey {
        typealias Value = CustomClient
    }

    var customClient: CustomClient {
        if let existing = storage[CustomClientKey.self] {
            return existing
        } else {
            let new = CustomClient()
            storage[CustomClientKey.self] = new
            return new
        }
    }
}

extension Application.Clients.Provider {
    static var custom: Self {
        .init {
            $0.clients.use { $0.customClient }
        }
    }
}
