// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 09/03/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI
import AVFoundation
import AVKit

final class AVCaptureController: UIViewController {
    var scanner: BarcodeScanner? = nil
    
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

extension AVCaptureController: BarcodeScannerDelegate {
    func detected(barcode: String) {
        print(barcode)
    }
    
    func attach(layer: CALayer) {
        view.layer.addSublayer(layer)
        layer.anchorPoint = .zero
        layer.position = .zero
        layer.frame = CGRect(origin: .zero, size: view.frame.size)
    }
}

struct AVCaptureView : UIViewControllerRepresentable {
    public func makeUIViewController(context: UIViewControllerRepresentableContext<AVCaptureView>) -> AVCaptureController {
        return AVCaptureController()
    }
    
    public func updateUIViewController(_ uiViewController: AVCaptureController, context: UIViewControllerRepresentableContext<AVCaptureView>) {
    }
    
}
