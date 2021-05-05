import XCTest
@testable import Wire

final class ResponseConvertibleTests: XCTestCase {
    func testClosureInit() {
        let converter = AnyResponseConvertible<String> { data -> Result<String, Error> in
            let aString = String(data: data, encoding: .utf8)!
            return .success(aString)
        }
        let data = try? converter.convert(data: #function.data(using: .utf8) ?? Data()).get()
        XCTAssertNotNil(data)
        XCTAssertEqual(data, #function)
    }

    func testGenericInit() {
        let converter = AnyResponseConvertible(StringIntConverter())
        let value = try? converter.convert(data: "100".data(using: .utf8) ?? Data()).get()
        XCTAssertEqual(value, 100)
    }

    func testFailure() {
        let converter = AnyResponseConvertible(StringIntConverter())
        XCTAssertThrowsError(try converter.convert(data: #function.data(using: .utf8) ?? Data()).get(), "") { error in
            XCTAssertEqual(error as? TestError, .failure)
        }
    }
}

private struct StringIntConverter: ResponseConvertible {
    func convert(data: Data) -> Result<Int, Error> {
        guard let aString = String(data: data, encoding: .utf8),
              let intValue = Int(aString) else {
            return .failure(TestError.failure)
        }
        return .success(intValue)
    }
}