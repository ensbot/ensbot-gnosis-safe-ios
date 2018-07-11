//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import MultisigWalletDomainModel
import Foundation
import CommonTestSupport
import Common

public final class MockNotificationService: NotificationDomainService {

    public var didPair = false
    public var didAuth = false

    public var shouldThrow = false
    public var shouldThrowNetworkError = false
    public var shouldThrowValidationFailedError = false
    public var delay: TimeInterval
    public var sentMessages: [String] = []

    public init(delay: TimeInterval = 0) {
        self.delay = delay
    }

    public func pair(pairingRequest: PairingRequest) throws {
        Timer.wait(delay)
        try throwIfNeeded()
        didPair = true
    }

    public func auth(request: AuthRequest) throws {
        Timer.wait(delay)
        didAuth = true
    }

    private func throwIfNeeded() throws {
        if shouldThrowNetworkError {
            throw JSONHTTPClient.Error.networkRequestFailed(URLRequest(url: URL(string: "http://test.url")!), nil, nil)
        }
        if shouldThrowValidationFailedError {
            throw NotificationDomainServiceError.validationFailed
        }
        if shouldThrow { throw TestError.error }
    }

    public func send(notificationRequest: SendNotificationRequest) throws {
        sentMessages.append("to:\(notificationRequest.devices.first!) msg:\(notificationRequest.message)")
    }

    public func safeCreatedMessage(at address: String) -> String {
        return "SafeCreatedMessage_\(address)"
    }

}
