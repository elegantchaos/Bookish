// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 04/03/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import AVFoundation
import Vision

protocol BarcodeScannerDelegate: AnyObject {
    func detected(barcode: String)
    func attach(layer: CALayer)
}

@objc class BarcodeScanner: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let session: AVCaptureSession
    let device: AVCaptureDevice
    weak var delegate: BarcodeScannerDelegate?
    
    var requests = [VNRequest]()
    
    init?(delegate: BarcodeScannerDelegate? = nil) {
        
        guard let device = AVCaptureDevice.default(for: AVMediaType.video) else {
            return nil
        }
        
        self.delegate = delegate
        self.session = AVCaptureSession()
        self.device = device
    }
    
    func run() {
        setupVideo()
        startDetection()
    }
    
    func shutdown() {
        session.stopRunning()
        requests.removeAll()
        delegate = nil
    }
    
    fileprivate func setupVideo() {
        session.sessionPreset = AVCaptureSession.Preset.photo
        let deviceInput = try! AVCaptureDeviceInput(device: device)
        
        let deviceOutput = AVCaptureVideoDataOutput()
        deviceOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        deviceOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.default))
        
        session.addInput(deviceInput)
        session.addOutput(deviceOutput)
        let imageLayer = AVCaptureVideoPreviewLayer(session: session)
        imageLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        delegate?.attach(layer: imageLayer)
        session.startRunning()
    }
    
    func startDetection() {
        weak var delegate = self.delegate
        let request = VNDetectBarcodesRequest(completionHandler: { (request: VNRequest, error: Error?) in
            if let observations = request.results {
                let barcodes = observations.compactMap({ ($0 as? VNBarcodeObservation)?.payloadStringValue })
                for barcode in barcodes {
                    delegate?.detected(barcode: barcode)
                }
            }
        })
        
        request.symbologies = [.EAN13]
        self.requests = [request]
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        var requestOptions:[VNImageOption:Any] = [:]
        if let camData = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil) {
            requestOptions = [.cameraIntrinsics:camData]
        }
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: CGImagePropertyOrientation(rawValue: 6)!, options: requestOptions)
        do {
            try imageRequestHandler.perform(self.requests)
        } catch {
            print(error)
        }
    }
}
