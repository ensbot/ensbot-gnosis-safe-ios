//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import MultisigWalletDomainModel

class EthSignatureTests: XCTestCase {

    func test_canEcnodeAndDecode() throws {
        let str =
            """
                { "v" : 35, "r" : "test", "s" : "it" }
            """
        let signature = EthSignature(r: "test", s: "it", v: 35)

        let decoder = JSONDecoder()
        let signature2 = try decoder.decode(EthSignature.self, from: str.data(using: .utf8)!)
        XCTAssertEqual(signature, signature2)

        let encoder = JSONEncoder()
        let data = try encoder.encode(signature)
        let signature3 = try decoder.decode(EthSignature.self, from: data)
        XCTAssertEqual(signature, signature3)
    }

}
