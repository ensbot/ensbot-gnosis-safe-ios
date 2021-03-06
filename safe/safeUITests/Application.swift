//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation
import XCTest
import CommonTestSupport

final class Application {

    private var arguments = [String]()
    private let app = XCUIApplication()

    enum ApplicationError {
        case none
        case networkError
        case validationError
        case genericError
    }

    func resetAllContentAndSettings() {
        arguments.append(ApplicationArguments.resetAllContentAndSettings)
    }

    func setPassword(_ password: String) {
        arguments.append(ApplicationArguments.setPassword)
        arguments.append(password)
    }

    func setSessionDuration(seconds duration: TimeInterval) {
        arguments.append(ApplicationArguments.setSessionDuration)
        arguments.append(String(duration))
    }

    func setMaxPasswordAttempts(_ attemptCount: Int) {
        arguments.append(ApplicationArguments.setMaxPasswordAttempts)
        arguments.append(String(attemptCount))
    }

    func setAccountBlockedPeriodDuration(_ time: TimeInterval) {
        arguments.append(ApplicationArguments.setAccountBlockedPeriodDuration)
        arguments.append(String(time))
    }

    func setMockServerResponseDelay(_ time: TimeInterval) {
        arguments.append(ApplicationArguments.setMockServerResponseDelay)
        arguments.append(String(time))
    }

    func setMockNotificationService(delay: TimeInterval, shouldThrow: ApplicationError) {
        var params = "delay=\(Int(delay))"
        switch shouldThrow {
        case .networkError:
            params += ",networkError"
        case .validationError:
            params += ",validationError"
        case .genericError:
            params += ",genericError"
        case .none:
            break
        }
        arguments.append(ApplicationArguments.setMockNotificationService)
        arguments.append(params)
    }

    func setMockTransactionRelayService(delay: TimeInterval, shouldThrow: ApplicationError) {
        var params = "delay=\(Int(delay))"
        switch shouldThrow {
        case .networkError:
            params += ",networkError"
        case .genericError:
            params += ",genericError"
        default:
            break
        }
        arguments.append(ApplicationArguments.setMockTransactionsRelayService)
        arguments.append(params)
    }

    func setTestSafe() {
        arguments.append(ApplicationArguments.setTestSafe)
    }

    func resetArguments() {
        arguments = []
    }

    func start() {
        app.launchArguments = arguments
        app.launch()
    }

    func minimize() {
        XCUIDevice.shared.press(.home)
    }

    func maximize() {
        app.activate()
    }

    func terminate() {
        // give some time to save data
        delay(1)
        app.terminate()
    }
}
