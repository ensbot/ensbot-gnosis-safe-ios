//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import UIKit
import MultisigWalletApplication
import Common
import SafeUIKit

protocol SendInputViewControllerDelegate: class {
    func didCreateDraftTransaction(id: String)
}

public class SendInputViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var nextBarButton: UIBarButtonItem!
    @IBOutlet weak var addressInput: AddressInput!
    @IBOutlet weak var tokenInput: TokenInput!
    @IBOutlet weak var accountBalanceHeaderView: AccountBalanceView!
    @IBOutlet weak var feeCalculationView: FeeCalculationView!

    weak var delegate: SendInputViewControllerDelegate?

    private var keyboardBehavior: KeyboardAvoidingBehavior!
    internal var model: SendInputViewModel!
    internal var transactionID: String?

    private var tokenID: BaseID!
    private var initialAddress: String?
    private var feeTokenID: BaseID {
        return BaseID(ApplicationServiceRegistry.walletService.feePaymentTokenData.address)
    }
    private var needsEstimation: Bool = false

    public static func create(tokenID: BaseID, address: String?) -> SendInputViewController {
        let controller = StoryboardScene.Main.sendInputViewController.instantiate()
        controller.tokenID = tokenID
        controller.initialAddress = address
        return controller
    }

    private enum Strings {
        static let titleFormatString = LocalizedString("send_title", comment: "Send")
        static let `continue` = LocalizedString("review", comment: "Review button for Send screen")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        contentView.backgroundColor = ColorName.snowwhite.color
        nextBarButton.title = SendInputViewController.Strings.continue
        nextBarButton.accessibilityIdentifier = "transaction.continue"
        keyboardBehavior = KeyboardAvoidingBehavior(scrollView: scrollView)

        model = SendInputViewModel(tokenID: tokenID) { [weak self] in
            self?.updateFromViewModel()
        }

        navigationItem.title = String(format: Strings.titleFormatString, model.accountBalanceTokenData.code)

        addressInput.addressInputDelegate = self
        addressInput.textInput.accessibilityIdentifier = "transaction.address"
        addressInput.spacingAfterInput = 0
        addressInput.text = initialAddress

        tokenInput.addRule("", identifier: "notEnoughFunds") { [weak self] in
            guard let `self` = self else { return true }
            let number = self.tokenInput.formatter.number(from: $0,
                                                          precision: self.model.accountBalanceTokenData.decimals)
            guard let amount = number else { return true }
            self.model.change(amount: amount.value)
            return self.model.hasEnoughFunds()
        }
        tokenInput.setUp(value: 0, decimals: model.accountBalanceTokenData.decimals)
        tokenInput.usesEthDefaultImage = true
        tokenInput.imageURL = model.accountBalanceTokenData.logoURL
        tokenInput.tokenCode = model.accountBalanceTokenData.code
        tokenInput.delegate = self
        tokenInput.textInput.accessibilityIdentifier = "transaction.amount"
        tokenInput.textInput.keyboardTargetView = tokenInput.superview

        setNeedsEstimation()

        DispatchQueue.main.async { [unowned self] in
            // For unknown reasons, the identicon does not show up if updated in the viewDidLoad
            guard let address = ApplicationServiceRegistry.walletService.selectedWalletAddress else { return }
            self.accountBalanceHeaderView.address = address
            self.accountBalanceHeaderView.name = ApplicationServiceRegistry.walletService.addressName(for: address)
        }
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        keyboardBehavior.start()
        updateFeeCalculationViewAndModel()
    }

    private func setNeedsEstimation() {
        needsEstimation = true
    }

    /// If user changed payment method, the fee calculation view should be updated with new fee token data.
    private func updateFeeCalculationViewAndModel() {
        guard needsEstimation else {
            return
        }
        needsEstimation = false
        feeCalculationView.calculation = tokenID == feeTokenID ? SameTransferAndPaymentTokensFeeCalculation() :
            DifferentTransferAndPaymentTokensFeeCalculation()
        model.resetEstimation()
        model.update()
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        trackEvent(SendTrackingEvent(.input,
                                     token: model.accountBalanceTokenData.address,
                                     tokenName: model.accountBalanceTokenData.code))

        if let target = feeCalculationView.viewWithTag(FeeCalculationAssetLine.settingsButtonTag) {
            TooltipControlCenter.showFirstTimeTooltip(persistenceKey: "io.gnosis.safe.payment_token.visited",
                                                      target: target,
                                                      parent: view,
                                                      text: LocalizedString("tap_to_change_token", comment: "Tap"))
        }
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        keyboardBehavior.stop()
    }

    func updateFromViewModel() {
        accountBalanceHeaderView.amount = model.accountBalanceTokenData
        if tokenID == feeTokenID {
            let calculation = SameTransferAndPaymentTokensFeeCalculation()
            calculation.networkFeeLine.set(valueButton: abs(model.feeEstimatedAmountTokenData),
                                           target: self,
                                           action: #selector(changePaymentMethod),
                                           roundUp: true)
            calculation.resultingBalanceLine.set(value: model.feeResultingBalanceTokenData)
            calculation.setBalanceError(feeBalanceError())
            feeCalculationView.calculation = calculation
        } else {
            let calculation = DifferentTransferAndPaymentTokensFeeCalculation()
            calculation.resultingBalanceLine.set(value: model.resultingBalanceTokenData)
            calculation.setBalanceError(tokenBalanceError())
            calculation.networkFeeLine.set(valueButton: abs(model.feeEstimatedAmountTokenData),
                                           target: self,
                                           action: #selector(changePaymentMethod),
                                           roundUp: true)
            calculation.networkFeeResultingBalanceLine.set(value: model.feeResultingBalanceTokenData)
            calculation.setFeeBalanceError(feeBalanceError())
            feeCalculationView.calculation = calculation
        }
        tokenInput.revalidateText()
        nextBarButton.isEnabled = model.canProceedToSigning && tokenInput.isValid
    }

    private func tokenBalanceError() -> Error? {
        let isNegativeBalance = (model.resultingBalanceTokenData.balance ?? 0) < 0
        return  model.hasEnoughFunds() == false && isNegativeBalance ? FeeCalculationError.insufficientBalance : nil
    }

    private func feeBalanceError() -> Error? {
        let isNegativeFeeBalance = (model.feeResultingBalanceTokenData.balance ?? 0) < 0
        return model.hasEnoughFunds() == false && isNegativeFeeBalance ? FeeCalculationError.insufficientBalance : nil
    }

    @IBAction func proceedToSigning(_ sender: Any) {
        let service = ApplicationServiceRegistry.walletService
        transactionID = service.createNewDraftTransaction(token: tokenID.id)
        service.updateTransaction(transactionID!,
                                  amount: model.amount ?? 0,
                                  token: tokenID.id,
                                  recipient: model.recipient!)
        delegate?.didCreateDraftTransaction(id: transactionID!)
    }

    func willBeRemoved() {
        if let id = transactionID {
            DispatchQueue.main.async {
                ApplicationServiceRegistry.walletService.removeDraftTransaction(id)
            }
        }
    }

    @objc func showTransactionFeeInfo() {
        present(UIAlertController.networkFee(), animated: true, completion: nil)
    }

    @objc private func changePaymentMethod() {
        let vc = PaymentMethodViewController()
        vc.delegate = self
        navigationController?.pushViewController(vc, animated: true)
    }

}

extension SendInputViewController: AddressInputDelegate {

    public func didRecieveInvalidAddress(_ string: String) {}

    public func didClear() {}

    public func presentController(_ controller: UIViewController) {
        present(controller, animated: true)
    }

    public func didRecieveValidAddress(_ address: String) {
        model.change(recipient: address)
    }

    public func nameForAddress(_ address: String) -> String? {
        return ApplicationServiceRegistry.walletService.addressName(for: address)
    }

    public func didRequestAddressBook() {
        let vc = AddressBookViewController(nibName: nil, bundle: nil)
        vc.pickerModeEnabled = true
        vc.delegate = self
        navigationController?.pushViewController(vc, animated: true)
    }

    public func didRequestENSName() {
        let vc = ENSInputViewController.create(delegate: self)
        navigationController?.pushViewController(vc, animated: true)
    }

}

extension SendInputViewController: VerifiableInputDelegate {

    public func verifiableInputDidReturn(_ verifiableInput: VerifiableInput) {
        if model.canProceedToSigning {
            proceedToSigning(verifiableInput)
        }
    }

    public func verifiableInputDidBeginEditing(_ verifiableInput: VerifiableInput) {
        keyboardBehavior.activeTextField = verifiableInput.textInput
    }

}

extension SendInputViewController: PaymentMethodViewControllerDelegate {

    func paymentMethodViewControllerDidChangePaymentMethod(_ controller: PaymentMethodViewController) {
        setNeedsEstimation()
    }

}

extension SendInputViewController: AddressBookViewControllerDelegate {

    func addressBookViewController(controller: AddressBookViewController, didSelect entry: AddressBookEntryData) {
        navigationController?.popViewController(animated: true)
        addressInput.text = entry.address
        model.change(recipient: entry.address)
    }

    func addressBookViewController(controller: AddressBookViewController, edit entry: AddressBookEntryData) {
        // no-op
    }

    func addressBookViewControllerCreateNewEntry(controller: AddressBookViewController) {
        // no-op
    }

}

extension SendInputViewController: ENSInputViewControllerDelegate {

    func ensInputViewControllerDidConfirm(_ controller: ENSInputViewController, address: String) {
        navigationController?.popViewController(animated: true)
        addressInput.text = address
        model.change(recipient: address)
    }

}
