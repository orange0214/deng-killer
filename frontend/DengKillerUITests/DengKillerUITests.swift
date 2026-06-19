import XCTest

final class DengKillerUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testMainDemoFlowShowsTranscriptClaimsAndReview() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.navigationBars["对话事实护盾"].waitForExistence(timeout: 5))

        app.buttons["startSimulationButton"].tap()

        XCTAssertTrue(app.staticTexts["FastAPI 比 Django 快是因为 FastAPI 是多线程。"].waitForExistence(timeout: 5))
        XCTAssertTrue(waitForAny(app, identifiers: ["alertSummaryCard", "发现 3 条可能错误"], timeout: 10))
        XCTAssertFalse(app.staticTexts["已忽略"].exists)
        XCTAssertFalse(app.staticTexts["claimStatus-ignored"].exists)

        app.buttons["reviewButton"].tap()

        XCTAssertTrue(app.navigationBars["会后复盘"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["某公司去年利润增长了 30%。"].waitForExistence(timeout: 5))
    }

    @MainActor
    private func waitForAny(_ app: XCUIApplication, identifiers: [String], timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if identifiers.contains(where: { app.descendants(matching: .any)[$0].exists }) {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }
        return false
    }
}
