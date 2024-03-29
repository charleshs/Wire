import Foundation

/**
 Defines the `modify(_:)` method that consumes a URLRequest and
 outputs a fallible result wrapping the modified request.
 */
public protocol RequestModifiable {
    /// Modifies a `URLRequest` and returns a fallible result wrapping the modified request.
    /// - Parameter request: The request being modified.
    func modify(_ request: URLRequest) -> Result<URLRequest, Error>
}
