//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import UIKit

public protocol ScanBarButtonItemDelegate: class {
    func presentController(_ controller: UIViewController)
    func didScanValidCode(_ button: ScanBarButtonItem, code: String)
}

public final class ScanBarButtonItem: UIBarButtonItem {

    public weak var delegate: ScanBarButtonItemDelegate?
    public var scanValidatedConverter: ScanValidatedConverter? {
        didSet {
            scanHandler.scanValidatedConverter = scanValidatedConverter
        }
    }
    var scanHandler = ScanQRCodeHandler()

    public convenience init(title: String) {
        self.init()
        self.title = title
        commonInit()
    }

    public override func awakeFromNib() {
        super.awakeFromNib()
        commonInit()
    }

    private func commonInit() {
        scanHandler.delegate = self
        action = #selector(scan)
    }

    @objc private func scan() {
        scanHandler.scan()
    }

    public func addDebugButtonToScannerController(title: String, scanValue: String) {
        scanHandler.addDebugButtonToScannerController(title: title, scanValue: scanValue)
    }

}

extension ScanBarButtonItem: ScanQRCodeHandlerDelegate {

    func presentController(_ controller: UIViewController) {
        delegate?.presentController(controller)
    }

    func didScanCode(raw: String, converted: String?) {
        self.delegate?.didScanValidCode(self, code: raw)
    }

}