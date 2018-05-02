//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import XCTest
import CommonTestSupport

class PairWithBrowserExtensionScreenUITests: UITestCase {

    let screen = PairWithBrowserExtensionScreen()
    var cameraPermissionHandler: NSObjectProtocol!
    var cameraSuggestionHandler: NSObjectProtocol!
    let cameraScreen = CameraScreen()

    override func setUp() {
        super.setUp()
        Springboard.deleteSafeApp()
        givenBrowserExtensionSetup()
    }

    override func tearDown() {
        if let handler = cameraPermissionHandler {
            removeUIInterruptionMonitor(handler)
        }
        if let handler = cameraSuggestionHandler {
            removeUIInterruptionMonitor(handler)
        }
        super.tearDown()
    }

    func test_contents() {
        XCTAssertExist(screen.qrCodeInput)
        XCTAssertExist(screen.finishButton)
        XCTAssertFalse(screen.finishButton.isEnabled)
    }

    func test_denyCameraAccess() {
        handleCameraPermissionByDenying()
        handleSuggestionAlertByCancelling(with: expectation(description: "Alerts handled"))
        screen.qrCodeInput.tap()
        handleAlerts()
    }

    func test_allowCameraAccess() {
        givenCameraOpened()
        closeCamera()
    }

    func test_scanInvalidCode() {
        givenCameraOpened()
        cameraScreen.scanInvalidCodeButton.tap()
        XCTAssertTrue(cameraScreen.isDisplayed)
        closeCamera()
    }

}

extension PairWithBrowserExtensionScreenUITests {

    private func handleCameraPermissionByDenying() {
        cameraPermissionHandler = addUIInterruptionMonitor(withDescription: "Camera access") { alert in
            guard alert.label.localizedCaseInsensitiveContains("would like to access the camera") else { return false }
            alert.buttons["Don’t Allow"].tap()
            return true
        }
    }

    private func handleCameraPermsissionByAllowing(with expectation: XCTestExpectation) {
        cameraPermissionHandler = addUIInterruptionMonitor(withDescription: "Camera access") { alert in
            defer { expectation.fulfill() }
            guard alert.label.localizedCaseInsensitiveContains("would like to access the camera") else {
                return false
            }
            alert.buttons["OK"].tap()
            return true
        }
    }

    private func handleSuggestionAlertByCancelling(with expectation: XCTestExpectation) {
        cameraSuggestionHandler = addUIInterruptionMonitor(withDescription: "Suggestion Alert") { alert in
            guard alert.label == XCLocalizedString("scanner.camera_access_required.title", table: "safeUIKit") else {
                return false
            }
            XCTAssertExist(alert.buttons[XCLocalizedString("scanner.camera_access_required.allow", table: "safeUIKit")])
            alert.buttons[XCLocalizedString("cancel", table: "safeUIKit")].tap()
            expectation.fulfill()
            return true
        }
    }

    private func closeCamera() {
        XCTAssertTrue(cameraScreen.isDisplayed)
        cameraScreen.closeButton.tap()
        XCTAssertExist(screen.qrCodeInput)
    }

    private func handleAlerts() {
        delay(1)
        XCUIApplication().tap() // required for alert handlers firing
        waitForExpectations(timeout: 5)
    }

    private func givenCameraOpened() {
        handleCameraPermsissionByAllowing(with: expectation(description: "Alert"))
        screen.qrCodeInput.tap()
        handleAlerts()
    }

}
