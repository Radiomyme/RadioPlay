//
//  RadioPlayUITests.swift
//  RadioPlayUITests
//
//  Created by Martin Parmentier on 17/05/2025.
//

import XCTest

class RadioPlayUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testStationsListDisplayed() {
        // Verify that the stations list is displayed
        XCTAssertTrue(app.tables.element.exists, "Stations list should be displayed")
    }

    func testNavigationToPlayerView() {
        // Tap on the first station
        let firstCell = app.tables.cells.element(boundBy: 0)
        XCTAssertTrue(firstCell.exists, "First station cell should exist")

        firstCell.tap()

        // Verify player controls are visible
        let playButton = app.buttons["play.circle.fill"]
        XCTAssertTrue(playButton.waitForExistence(timeout: 5), "Play button should be visible")
    }
}
