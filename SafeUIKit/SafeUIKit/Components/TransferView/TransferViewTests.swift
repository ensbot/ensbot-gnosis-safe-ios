//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import SafeUIKit
import Common

class TransferViewTests: XCTestCase {

    let transferView = TransferView()
    let tokenData = TokenData(address: "", code: "TEST", name: "", logoURL: "", decimals: 5, balance: 123_456)

    func test_whenSettingFromAddress_thenSetsProperties() {
        XCTAssertEqual(transferView.fromAddressLabel.text, "")
        XCTAssertEqual(transferView.fromIdenticonView.seed, "")
        transferView.fromAddress = "from_address"
        XCTAssertEqual(transferView.fromAddressLabel.text, "from_address")
        XCTAssertEqual(transferView.fromIdenticonView.seed, "from_address")
    }

    func test_whenSettingToAddress_thenSetsProperties() {
        XCTAssertEqual(transferView.toAddressLabel.text, "")
        XCTAssertEqual(transferView.toIdenticonView.seed, "")
        transferView.toAddress = "to_address"
        XCTAssertEqual(transferView.toAddressLabel.text, "to_address")
        XCTAssertEqual(transferView.toIdenticonView.seed, "to_address")
    }

    func test_whenSettingTokenData_thenSetsProperties() {
        XCTAssertEqual(transferView.amountLabel.text, "")
        transferView.tokenData = tokenData
        XCTAssertEqual(transferView.amountLabel.text?.replacingOccurrences(of: ",", with: "."), "- 1.2345 TEST")
    }

    func test_whenSettingNilValues_thenIgnorsIt() {
        transferView.fromAddress = "from_address"
        transferView.toAddress = "to_address"
        transferView.tokenData = tokenData
        transferView.fromAddress = nil
        transferView.toAddress = nil
        transferView.tokenData = nil
        XCTAssertEqual(transferView.fromAddressLabel.text, "from_address")
        XCTAssertEqual(transferView.fromIdenticonView.seed, "from_address")
        XCTAssertEqual(transferView.toAddressLabel.text, "to_address")
        XCTAssertEqual(transferView.toIdenticonView.seed, "to_address")
        XCTAssertEqual(transferView.amountLabel.text?.replacingOccurrences(of: ",", with: "."), "- 1.2345 TEST")
    }

}