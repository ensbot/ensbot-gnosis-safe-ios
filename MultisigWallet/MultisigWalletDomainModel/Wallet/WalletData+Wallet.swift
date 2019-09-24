//
//  Copyright © 2019 Gnosis Ltd. All rights reserved.
//

import Foundation
import Common

public extension WalletData {

    init?(wallet: Wallet) {
        var walletState: WalletData.State!
        if wallet.state.isCreationInProgress ||
            wallet.state.isRecoveryInProgress ||
            wallet.state.isFinalizingRecovery {
            walletState = .pending
        } else if wallet.state.isReadyToUse {
            walletState = .created
        } else {
            return nil
        }
        self.init(address: wallet.address.value, name: "Wallet", state: walletState)
    }

}
