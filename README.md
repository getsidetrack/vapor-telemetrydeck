<p align="center">
    TelemetryDeck client for Vapor
    <br>
    <br>
    <a href="https://docs.vapor.codes/4.0/">
        <img src="http://img.shields.io/badge/read_the-docs-2196f3.svg" alt="Documentation">
    </a>
    <a href="https://discord.gg/vapor">
        <img src="https://img.shields.io/discord/431917998102675485.svg" alt="Team Chat">
    </a>
    <a href="LICENSE">
        <img src="http://img.shields.io/badge/license-MIT-brightgreen.svg" alt="MIT License">
    </a>
    <a href="https://github.com/getsidetrack/vapor-telemetrydeck/actions">
        <img src="https://github.com/getsidetrack/vapor-telemetrydeck/workflows/test/badge.svg" alt="Continuous Integration">
    </a>
    <a href="https://swift.org">
        <img src="http://img.shields.io/badge/swift-5.2-brightgreen.svg" alt="Swift 5.2">
    </a>
</p>


## Usage

Once you have added the package to your project, you must initialise the library. This is usually done in `configure.swift`.

```swift
import TelemetryDeck

app.telemetryDeck.initialise(appID: "<YOUR-APP-ID>")
```

### Sending a Signal

There are two ways to send a signal. One method is from the "system", which contains a static user identifier.

```swift
try await app.telemetryDeck.send("applicationStarted")
```

The second option is from a request, this will set the user identifier to be a hashed version of the request IP address.

```swift
try await request.telemetryDeck.send("homePage")

// for example:

app.get("home") { req async throws -> String in
  try await req.telemetryDeck.send("homePage")
  return "your page content"
}
```

### Properties

You can attach additional payload data with each signal by adding `additionalPayload` to the send functions.

```swift
try await app.telemetryDeck.send("applicationStarted", additionalPayload: [
  "host": "gcp"
])
```

You may also configure TelemetryDeck for Vapor with a dictionary of default properties which are sent with every signal.

```swift
app.telemetryDeck.defaultParameters["key"] = "value"
```

## Sessions

With each signal, we send through a session identifier which is a unique UUID generated on initialisation. This is intended
to be different for each running instance of your server, changing each time you reboot the server.

## Test Mode

If you launch Vapor in a non-release environment, signals will be marked as being in test mode. In the Telemetry Viewer app, 
actvivate **Test Mode** to see those.

## Signal Batching

This library does not currently support signal batching. This means that signals are sent to TelemetryDeck as you call the functions. 
In a future release, we may add the capability to batch signals in memory and post them at regular intervals.
