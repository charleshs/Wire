#if canImport(Combine)
import Combine
#endif
import Foundation

/// `Request` defines the handling of a networking request, including the generation and modification
/// of `URLRequest` and transformation of the retrieved data into an `Output`.
public struct Request<Output> {
    private let builder: RequestBuildable
    private let requestModifiers: [RequestModifiable]
    private let dataModifiers: [DataModifiable]
    private let responseConversion: (Data) -> Result<Output, Error>

    private var dataModificationConverter: AnyResponseConverter<Data> {
        return AnyResponseConverter { data in
            modify(data: data)
        }
    }

    public init(
        builder: RequestBuildable,
        requestModifiers: [RequestModifiable] = [],
        dataModifiers: [DataModifiable] = [],
        conversion: @escaping (Data) -> Result<Output, Error>
    ) {
        self.builder = builder
        self.requestModifiers = requestModifiers
        self.dataModifiers = dataModifiers
        self.responseConversion = conversion
    }

    public init(
        builder: RequestBuildable,
        requestModifiers: [RequestModifiable] = [],
        dataModifiers: [DataModifiable] = [],
        conversion: @escaping (Data) throws -> Output
    ) {
        self.init(builder: builder, requestModifiers: requestModifiers, dataModifiers: dataModifiers) { data in
            return Result { try conversion(data) }
        }
    }

    public init<T>(
        builder: RequestBuildable,
        requestModifiers: [RequestModifiable] = [],
        dataModifiers: [DataModifiable] = [],
        responseConverter: T
    )
    where T: ResponseConvertible, T.Output == Output {
        self.init(builder: builder, requestModifiers: requestModifiers, dataModifiers: dataModifiers) { data in
            return responseConverter.convert(data: data)
        }
    }

    public init(
        builder: RequestBuildable,
        requestModifiers: [RequestModifiable] = [],
        dataModifiers: [DataModifiable] = []
    )
    where Output == Data {
        self.init(builder: builder, requestModifiers: requestModifiers, dataModifiers: dataModifiers) { data in
            return data
        }
    }

    /// Applies modification on the data with each element of the `dataModifiers`.
    func modify(data: Data) -> Result<Data, Error> {
        let modifiers = dataModifiers.map {
            Modifier<Data>(closure: $0.modify)
        }
        return iterateFallibleModifiers(initial: data, modifiers)
    }

    private struct Modifier<T> {
        let closure: (T) -> Result<T, Error>
    }

    private func iterateFallibleModifiers<T>(initial: T, _ modifiers: [Modifier<T>]) -> Result<T, Error> {
        var buffer = initial
        for modifier in modifiers {
            switch modifier.closure(buffer) {
            case .failure(let error): return .failure(error)
            case .success(let value): buffer = value
            }
        }
        return .success(buffer)
    }
}

extension Request: RequestBuildable {
    public func buildRequest() -> Result<URLRequest, Error> {
        let requestModifiers = requestModifiers.map {
            Modifier<URLRequest>(closure: $0.modify)
        }
        return builder.buildRequest().flatMap { request in
            iterateFallibleModifiers(initial: request, requestModifiers)
        }
    }
}

extension Request: ResponseConvertible {
    public func convert(data: Data) -> Result<Output, Error> {
        return modify(data: data).flatMap(responseConversion)
    }
}

extension Request {
    public func retrieveData(
        using client: DataTaskClient = .shared,
        completion: @escaping (Result<Data, WireError>) -> Void
    ) {
        client.retrieveObject(with: self, responseConverter: dataModificationConverter, completion: completion)
    }

    public func retrieveObject(
        using client: DataTaskClient = .shared,
        completion: @escaping (Result<Output, WireError>) -> Void
    ) {
        client.retrieveObject(with: self, responseConverter: self, completion: completion)
    }
}

@available(iOS 13.0, tvOS 13.0, watchOS 6.0, OSX 10.15, *)
extension Request {
    public func dataPublisher(using client: DataTaskClient = .shared) -> AnyPublisher<Data, WireError> {
        return client.objectPublisher(with: self, responseConverter: dataModificationConverter)
    }

    public func objectPublisher(using client: DataTaskClient = .shared) -> AnyPublisher<Output, WireError> {
        return client.objectPublisher(with: self, responseConverter: self)
    }
}

#if swift(>=5.5)
@available(iOS 15.0, tvOS 15.0, watchOS 8.0, OSX 12.0, *)
extension Request {
    public func data(using client: DataTaskClient = .shared) async throws -> Data {
        return try await client.object(with: self, objectConverter: asDataConverter)
    }

    public func object(using client: DataTaskClient = .shared) async throws -> Output {
        return try await client.object(with: self, objectConverter: AnyResponseConvertible(transform: responseConversion))
    }
}
#endif
