//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import MultisigWalletDomainModel
import CommonTestSupport

class BrowserExtensionCodeTests: XCTestCase {

    func test_canEcnodeAndDecode() throws {
        let dateFormatter = WalletDateFormatter()

        let date = dateFormatter.date(from: "2018-05-09T14:18:55+00:00")!
        let signature = RSVSignature(r: "test", s: "me", v: 27)
        let code = BrowserExtensionCode(expirationDate: date, signature: signature)

        let code2 = try BrowserExtensionCode(json: BrowserExtensionFixture.testJSON)
        XCTAssertEqual(code, code2)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(dateFormatter)
        let data = try encoder.encode(code)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        let code3 = try decoder.decode(BrowserExtensionCode.self, from: data)
        XCTAssertEqual(code, code3)
    }

}