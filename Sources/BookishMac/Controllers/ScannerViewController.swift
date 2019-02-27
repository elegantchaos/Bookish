// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 26/02/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import AVFoundation
import Vision
import Foundation

class ScannerViewController: NSViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    
    @IBOutlet weak var imageView: NSView!
    @IBOutlet weak var barcodeView: NSTextField!
    @IBOutlet weak var infoView: NSTextView!
    
    var captureDevice: AVCaptureDevice!
    var session = AVCaptureSession()
    var requests = [VNRequest]()
    var detected: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupVideo()
        self.startDetection()
    }
    
    func setupVideo() {
        session.sessionPreset = AVCaptureSession.Preset.photo
        captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
        let deviceInput = try! AVCaptureDeviceInput(device: captureDevice!)
        
        let deviceOutput = AVCaptureVideoDataOutput()
        deviceOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        deviceOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.default))
       
        session.addInput(deviceInput)
        session.addOutput(deviceOutput)
        let imageLayer = AVCaptureVideoPreviewLayer(session: session)
        imageLayer.frame = imageView.bounds
        imageLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        imageView.layer = imageLayer
        session.startRunning()
    }
    
    func startDetection() {
        let request = VNDetectBarcodesRequest(completionHandler: self.detectHandler)
        request.symbologies = [.EAN13, .EAN8] // or use .QR, etc
        self.requests = [request]
    }
    
    func detectHandler(request: VNRequest, error: Error?) {
        guard let observations = request.results else {
            //print("no result")
            return
        }
        let results = observations.map({$0 as? VNBarcodeObservation})
        for result in results {
            if let value = result?.payloadStringValue, detected != value {
                DispatchQueue.main.async {
                    self.detected(ean: value)
                }
                lookup(ean: value)
            }
        }
    }
    
    func detected(ean: String) {
        detected = ean
        barcodeView.stringValue = ean
    }
    
    func lookup(ean: String) {
        if let url = URL(string: "https://www.googleapis.com/books/v1/volumes?q=isbn:\(ean)") {
            if let data = try? Data(contentsOf: url) {
                if let parsed = try? JSONSerialization.jsonObject(with: data, options: []), let data = parsed as? [String:Any] {
                    DispatchQueue.main.async {
                        self.found(data: data)
                    }
                }
            }
        }
    }
    
    func found(data: [String:Any]) {
        if let items = data["items"] as? [[String:Any]] {
            if items.count > 0, let item = items[0]["volumeInfo"] as? [String:Any] {
                var summary = ""
                if let title = item["title"] as? String {
                    summary += "\(title)\n"
                }
                if let authors = item["authors"] as? [String] {
                    summary += authors.joined(separator: ", ")
                    summary += "\n"
                }
                if let publisher = item["publisher"] as? String {
                    summary += "\(publisher)\n"
                }
                if let publishedDate = item["publishedDate"] as? String {
                    let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
                    if let matches = detector?.matches(in: publishedDate, options: NSRegularExpression.MatchingOptions(), range: NSRange(location: 0, length: publishedDate.count)) {
                        if let date = matches.first?.date {
                            summary += "\(date)"
                        }
                    }
                }
                infoView.string = summary
            }
        }
    }
    
    @IBAction func doTest(_ sender: Any) {
        detected(ean: "9781408832240")
        lookup(ean: "9781408832240")
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
