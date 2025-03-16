//
//  LoggerClient.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 17.11.2024.
//

import ComposableArchitecture
@preconcurrency import OSLog

public enum LoggerCategory: String, Sendable {
    case app
    case deeplink
    case analytics
    case notifications
    case bbbuilder
}

extension Logger: @retroactive DependencyKey {
    public static var liveValue: Logger { Logger() }
    /// - Note: It doesn't make a lot of sense to fail by default because we can't pass an
    /// inspectable `Logger` value to assert logged messages when testing. Given the prominence of
    /// logging failing by default is more annoying than useful in real-life scenarios.
    /// Users who wish to assert that no logging occurs can override the `\.logger` dependency with
    /// the `.unimplemented` logger.
    public static var testValue: Logger { Logger() }
    public static var previewValue: Logger { Logger() }
    
    /// A `Logger` that fails when accessed while testing.
    public static var unimplemented: Logger {
        XCTFail(#"Unimplemented: @Dependency(\.logger)"#)
        return Logger()
    }
}

extension Logger: @retroactive TestDependencyKey {}

extension Logger {
    /// Creates a logger using the specified subsystem and category.
    ///
    /// You can use this subscript on the `\.logger` dependency:
    /// ```swift
    /// @Dependency(\.logger[subsystem: "Backend", category: "Transactions"]) var logger
    ///
    /// logger.log("Paid with bank account \(accountNumber)")
    /// ```
    public subscript(subsystem subsystem: String, category category: String) -> Logger {
        Logger(subsystem: subsystem, category: category)
    }
    /// Creates a `Logger` value where messages are categorized by the provided argument.
    /// The `Logger`'s subsystem is the bundle identifier.
    ///
    /// You can use this subscript on the `\.logger` dependency:
    /// ```swift
    /// @Dependency(\.logger["Transactions"]) var logger
    ///
    /// logger.log("Paid with bank account \(accountNumber)")
    /// ```
    public subscript(category: String) -> Logger {
        Logger(subsystem: Bundle.main.bundleIdentifier ?? "", category: category)
    }
    
    public subscript(category: LoggerCategory, isEnabled: Bool = true) -> Logger {
        if isEnabled {
            return Logger(subsystem: Bundle.main.bundleIdentifier ?? "", category: category.rawValue.capitalized)
        } else {
            return Logger(.disabled)
        }
    }
}

extension DependencyValues {
    /// A value for writing interpolated string messages to the unified logging system.
    public var logger: Logger {
        get { self[Logger.self] }
        set { self[Logger.self] = newValue }
    }
}

extension Logger {
    public var signpost: OSSignposter {
        OSSignposter(logger: self)
    }
}
