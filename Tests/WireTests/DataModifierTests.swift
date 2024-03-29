import XCTest
@testable import Wire

final class DataModifierTests: XCTestCase {
    func testSuccess() throws {
        let dataModifier = AnyDataModifier { data in
            return .success("Modified".data(using: .utf8) ?? Data())
        }
        let data = try dataModifier.modify(Data()).get()

        XCTAssertEqual(data, "Modified".data(using: .utf8))
    }

    func testFailure() {
        let dataModifier = AnyDataModifier(FailureModifier())

        XCTAssertThrowsError(try dataModifier.modify(Data()).get(), "") { error in
            XCTAssertEqual(error as? TestError, .failure)
        }
    }
}

private struct FailureModifier: DataModifiable {
    func modify(_ input: Data) -> Result<Data, Error> {
        return .failure(TestError.failure)
    }
}
