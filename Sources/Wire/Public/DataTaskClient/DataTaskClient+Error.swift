import Foundation

extension DataTaskClient {
    public enum PerformError: LocalizedError {
        /// `URLError` from `URLSession`. The `error` is ignored upon evaluating equality.
        case sessionError(_ error: Error)
        /// No response from server
        case noResponse
        /// The response is not HTTP. The `response` is ignored upon evaluating equality.
        case notHttpResponse(response: URLResponse)
        /// HTTP response with status code other than 200. Only the `code` is taken into equality evaluation.
        case httpStatus(code: Int, data: Data?)
        /// The response (200 OK) does not contain data.
        case noData

        public var errorDescription: String? {
            switch self {
            case .sessionError(let error):
                return "URLError: \(error.localizedDescription)"
            case .noResponse:
                return "Server did not provide a response."
            case .notHttpResponse(let response):
                return "Not HTTP: \(response)."
            case .httpStatus(let code, let data):
                return """
                "HTTP response status code: \(code), with data:\"
                "\(data.mapNil(as: Data()).utf8String(or: "* Content Not UTF-8 *"))\"
                """
            case .noData:
                return "Server did not provide data."
            }
        }
    }
}

extension DataTaskClient.PerformError: Equatable {
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.httpStatus(let lc, let ld), .httpStatus(let rc, let rd)):
            return lc == rc && ld == rd
        case (.sessionError, .sessionError),
            (.noResponse, .noResponse),
            (.notHttpResponse, .notHttpResponse),
            (.noData, .noData):
            return true
        default:
            return false
        }
    }
}
