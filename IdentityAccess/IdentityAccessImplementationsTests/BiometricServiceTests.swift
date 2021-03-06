//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import XCTest
import LocalAuthentication
@testable import IdentityAccessImplementations
import IdentityAccessDomainModel
import IdentityAccessApplication
import Common

class BiometricAuthenticationServiceTests: XCTestCase {

    var biometricService: BiometricAuthenticationService!
    let context = MockLAContext()

    override func setUp() {
        super.setUp()
        ApplicationServiceRegistry.put(service: MockLogger(), for: Logger.self)
        biometricService = BiometricService(localAuthenticationContext: self.context)
    }

    func test_activate_whenBiometricIsNotAvailable_thenIsNotActivated() throws {
        context.canEvaluatePolicy = false
        try activate()
        XCTAssertFalse(context.evaluatePolicyInvoked)
    }

    func test_activate_whenBiometricIsAvailable_thenIsActivated() throws {
        context.canEvaluatePolicy = true
        try activate()
        XCTAssertTrue(context.evaluatePolicyInvoked)
    }

    func test_authenticate_whenAvailableAndSuccess_thenAuthenticated() {
        context.canEvaluatePolicy = true
        XCTAssertTrue(authenticate())
        XCTAssertTrue(context.evaluatePolicyInvoked)
    }

    func test_authenticate_whenNotAvailable_thenNotAuthenticated() {
        context.canEvaluatePolicy = false
        XCTAssertFalse(authenticate())
        XCTAssertFalse(context.evaluatePolicyInvoked)
    }

    func test_authenticate_whenAvailableAndFails_thenNotAuthenticated() {
        context.canEvaluatePolicy = true
        context.policyShouldSucceed = false
        XCTAssertFalse(authenticate())
    }

    func test_isAuthenticationAvailable_whenCanEvaluatePolicy_thenTrue() {
        context.canEvaluatePolicy = true
        XCTAssertTrue(biometricService.isAuthenticationAvailable)
    }

    @available(iOS 10.0, *)
    func test_iOS_10_0_biometryType_whenNotAvailable_thenNone() {
        context.canEvaluatePolicy = false
        XCTAssertEqual(biometricService.biometryType, .none)
    }

    @available(iOS 10.0, *)
    func test_iOS_10_0_biometryType_whenAvailable_thenTouchID() {
        context.canEvaluatePolicy = true
        XCTAssertEqual(biometricService.biometryType, .touchID)
    }

    @available(iOS 11.0, *)
    func test_iOS_11_0_biometryType_whenNotAvailable_thenNone() {
        context.canEvaluatePolicy = false
        XCTAssertEqual(biometricService.biometryType, .none)
    }

    @available(iOS 11.0, *)
    func test_iOS_11_0_biometryType_whenAvailableAndBiometryFaceID_thenFaceID() {
        context.canEvaluatePolicy = true
        context.isBiometryTypeFaceID = true
        XCTAssertEqual(biometricService.biometryType, .faceID)
    }

    @available(iOS 11.0, *)
    func test_iOS_11_0_biometryType_whenAvailableAndBiometryTouchID_thenFaceID() {
        context.canEvaluatePolicy = true
        context.isBiometryTypeFaceID = false
        context.isBiometryTypeNone = false
        XCTAssertEqual(biometricService.biometryType, .touchID)
    }

    @available(iOS 11.0, *)
    func test_iOS_11_0_biometryType_whenAvailableAndBiometryNone_thenNone() {
        context.canEvaluatePolicy = true
        context.isBiometryTypeFaceID = false
        context.isBiometryTypeNone = true
        XCTAssertEqual(biometricService.biometryType, .none)
    }

}

extension BiometricAuthenticationServiceTests {

    func authenticate() -> Bool {
        context.evaluatePolicyInvoked = false
        let success = try! biometricService.authenticate()
        return success
    }

    func activate() throws {
        context.evaluatePolicyInvoked = false
        try biometricService.activate()
    }

}

class MockLAContext: LAContext {

    var canEvaluatePolicy = true
    var evaluatePolicyInvoked = false
    var policyShouldSucceed = true
    var isBiometryTypeFaceID = false
    var isBiometryTypeNone = false

    @available(iOS 11.0, *)
    override var biometryType: LABiometryType {
        if #available(iOS 11.2, *) {
            return isBiometryTypeFaceID ? .faceID : (isBiometryTypeNone ? .none : .touchID)
        } else {
            return isBiometryTypeFaceID ? .faceID : (isBiometryTypeNone ? .LABiometryNone : .touchID)
        }
    }

    override func canEvaluatePolicy(_ policy: LAPolicy, error: NSErrorPointer) -> Bool {
        return canEvaluatePolicy
    }

    override func evaluatePolicy(_ policy: LAPolicy, localizedReason: String, reply: @escaping (Bool, Error?) -> Void) {
        evaluatePolicyInvoked = true
        reply(policyShouldSucceed, nil)
    }

}
