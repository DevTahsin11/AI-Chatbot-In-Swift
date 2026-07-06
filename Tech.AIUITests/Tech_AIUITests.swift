//
//  Tech_AIUITests.swift
//  Tech.AIUITests
//
//  Created by Tahsin Ahmed  on 6/6/25.
//

import XCTest

final class Tech_AIUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    @MainActor
    func testSendButtonDisabledWhenInputIsEmpty() throws {
        let app = XCUIApplication()
        app.launch()

        let sendButton = app.buttons["sendButton"]
        XCTAssertTrue(sendButton.waitForExistence(timeout: 5))
        XCTAssertFalse(sendButton.isEnabled, "Send should be disabled with empty input.")
    }

    @MainActor
    func testTypingAndSendingShowsUserMessage() throws {
        let app = XCUIApplication()
        app.launch()

        let field = app.textFields["messageField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText("What is Big-O?")

        let sendButton = app.buttons["sendButton"]
        XCTAssertTrue(sendButton.isEnabled, "Send should enable once text is entered.")
        sendButton.tap()

        // The user's own message bubble should appear immediately,
        // independent of the network response.
        XCTAssertTrue(app.staticTexts["What is Big-O?"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testClearChatEmptiesConversation() throws {
        let app = XCUIApplication()
        app.launch()

        let field = app.textFields["messageField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText("Hello there")
        app.buttons["sendButton"].tap()

        XCTAssertTrue(app.staticTexts["Hello there"].waitForExistence(timeout: 5))

        app.buttons["clearButton"].tap()

        XCTAssertFalse(app.staticTexts["Hello there"].exists, "Clear Chat should remove messages.")
    }

    @MainActor
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
