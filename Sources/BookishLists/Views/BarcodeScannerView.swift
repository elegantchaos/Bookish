// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 09/03/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

typealias BarcodeCallback = (String) -> ()

final class BarcodeScannerController: UIViewController {
    var scanner: BarcodeScanner?
    var callback: BarcodeCallback?
    
    override func loadView() {
        scanner = BarcodeScanner(delegate: self)
        
        view = UIView()
        view.backgroundColor = .lightGray
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        scanner?.run()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        scanner?.shutdown()
    }
}

extension BarcodeScannerController: BarcodeScannerDelegate {
    func detected(barcode: String) {
        callback?(barcode)
    }
    
    func attach(layer: CALayer) {
        view.layer.addSublayer(layer)
        layer.anchorPoint = .zero
        layer.position = .zero
        layer.frame = CGRect(origin: .zero, size: view.frame.size)
    }
}

struct BarcodeScannerView : UIViewControllerRepresentable {
    let callback: BarcodeCallback
    
    public func makeUIViewController(context: UIViewControllerRepresentableContext<BarcodeScannerView>) -> BarcodeScannerController {
        let controller = BarcodeScannerController()
        controller.callback = callback
        return controller
    }
    
    public func updateUIViewController(_ uiViewController: BarcodeScannerController, context: UIViewControllerRepresentableContext<BarcodeScannerView>) {
    }
    
}
