//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import UIKit
import RSBarcodes
import AVFoundation

final public class QRCodeView: BaseCustomView {

    public var value: String? {
        didSet {
            update()
        }
    }

    public var padding: CGFloat = 0 {
        didSet {
            guard padding > 0 && padding < bounds.width / 2 else { return }
            imageView.frame = CGRect(
                x: bounds.minX + padding,
                y: bounds.minY + padding,
                width: bounds.width - 2 * padding,
                height: bounds.height - 2 * padding)
        }
    }

    internal let imageView = UIImageView()
    private let loadingLabel = UILabel()

    override public func commonInit() {
        imageView.accessibilityIdentifier = "qr code"
        imageView.frame = bounds
        imageView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        addSubview(imageView)
        loadingLabel.text = LocalizedString("loading", comment: "Loading")
        loadingLabel.font = UIFont.systemFont(ofSize: 10)
        loadingLabel.textAlignment = .center
        loadingLabel.frame = bounds
        loadingLabel.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        addSubview(loadingLabel)
        loadingLabel.isHidden = true
        update()
    }

    // QR-code generation takes significant time to load the first time, so it is off-loaded to background
    // and we show a placeholder "loading" text instead.
    override public func update() {
        guard let value = value else { return }
        let size = imageView.bounds.size
        loadingLabel.isHidden = false
        DispatchQueue.global().async { [weak self] in
            let generator = RSUnifiedCodeGenerator.shared
            generator.fillColor = ColorName.snowwhite.color
            generator.strokeColor = ColorName.black.color
            let type = AVMetadataObject.ObjectType.qr.rawValue
            guard let codeImage = generator.generateCode(value, machineReadableCodeObjectType: type),
                let finalImage = RSAbstractCodeGenerator.resizeImage(codeImage,
                                                                     targetSize: size,
                                                                     contentMode: .scaleAspectFit) else { return }
            DispatchQueue.main.async {
                guard let `self` = self, self.value == value else { return }
                self.loadingLabel.isHidden = true
                self.imageView.image = finalImage
            }
        }
    }

}
