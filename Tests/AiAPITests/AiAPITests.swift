import XCTest
@testable import AiAPI

final class AiAPITests: XCTestCase {
    func testExample() throws {
        // XCTest Documentation
        // https://developer.apple.com/documentation/xctest

        // Defining Test Cases and Test Methods
        // https://developer.apple.com/documentation/xctest/defining_test_cases_and_test_methods
    }
}

class URLExtensionsTests: XCTestCase {

    func testDaVinciURL() {
        // Test default version
        XCTAssertEqual(URL.davinci().absoluteString, "https://api.openai.com/v1/engines/davinci/completions")

        // Test specific version
        XCTAssertEqual(URL.davinci(version: 3).absoluteString, "https://api.openai.com/v3/engines/davinci/completions")

        // Test negative version
    }

    func testGPT35TurboURL() {
        // Test default version
        XCTAssertEqual(URL.gpt35Turbo().absoluteString, "https://api.openai.com/v1/chat/completions")

        // Test specific version
        XCTAssertEqual(URL.gpt35Turbo(version: 2).absoluteString, "https://api.openai.com/v2/chat/completions")

        // Test zero version
        XCTAssertEqual(URL.gpt35Turbo(version: 0).absoluteString, "https://api.openai.com/v0/chat/completions")
    }

    func testModelsURL() {
        // Test default version
        XCTAssertEqual(URL.models().absoluteString, "https://api.openai.com/v1/models")

        // Test specific version
        XCTAssertEqual(URL.models(version: 4).absoluteString, "https://api.openai.com/v4/models")
    }
}
