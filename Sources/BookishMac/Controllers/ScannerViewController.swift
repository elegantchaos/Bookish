// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 26/02/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import AVFoundation
import Vision
import Foundation
import BookishModel

class ScannerViewController: NSViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    
    @IBOutlet weak var imageView: NSView!
    @IBOutlet weak var barcodeView: NSTextField!
    @IBOutlet weak var candidatesTable: NSTableView!
    @IBOutlet weak var lookupSpinner: NSProgressIndicator!
    
    
    var captureDevice: AVCaptureDevice!
    var session = AVCaptureSession()
    var requests = [VNRequest]()
    var detected: String = ""
    var lookup: LookupSession? = nil
    var candidates: [LookupCandidate] = []
    
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
        lookup?.cancel()
        lookup = application.lookupManager.lookup(ean: ean) { (session, state) in
            self.lookupUpdate(session: session, state: state)
        }
    }
    
    func lookupUpdate(session: LookupSession, state: LookupSession.State) {
        switch state {
        case .starting:
            barcodeView.stringValue = "Starting lookup for \(session.search)."
            lookupSpinner.startAnimation(self)
            lookupSpinner.isHidden = false
            candidates.removeAll()
            
        case .done:
            barcodeView.stringValue = "\n\nFinished lookup."
            lookupSpinner.stopAnimation(self)
            lookupSpinner.isHidden = true

        case .foundCandidate(let candidate):
            candidates.append(candidate)
            candidatesTable.reloadData()
            
        default:
            break
        }
    }

    
    @IBAction func doTest(_ sender: Any) {
        detected(ean: "9781408832240")
        lookup(ean: "9781408832240")
    }
    
    @IBAction func doAdd(_ sender: Any) {
        let state = application.viewModel
        if let candidate = candidates.first, let context = state?.managedObjectContext {
            let book = candidate.makeBook(in: context)
            application.windowController.reveal(book: book)
        }
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

extension ScannerViewController: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return candidates.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "candidate"), owner: self) as! NSTableCellView
        view.textField?.stringValue = candidates[row].summary
        return view
    }
}
