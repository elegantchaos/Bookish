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
    
    static let candidateViewID = NSUserInterfaceItemIdentifier(rawValue: "candidate")
    
    @IBOutlet weak var imageView: NSView!
    @IBOutlet weak var barcodeView: NSTextField!
    @IBOutlet weak var candidatesTable: NSTableView!
    @IBOutlet weak var lookupSpinner: NSProgressIndicator!
    @IBOutlet weak var addButton: NSButton!
    
    var captureDevice: AVCaptureDevice!
    var session = AVCaptureSession()
    var requests = [VNRequest]()
    var detected: String = ""
    var lookup: LookupSession? = nil
    var candidates: [LookupCandidate] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        barcodeView.stringValue = "candidate.lookup.scanning".localized
        candidatesTable.isHidden = true
        
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
        let request = VNDetectBarcodesRequest(completionHandler: { (request: VNRequest, error: Error?) in
            if let observations = request.results {
                let barcodes = observations.compactMap({ ($0 as? VNBarcodeObservation)?.payloadStringValue })
                for barcode in barcodes {
                    self.detected(barcode: barcode)
                }
            }
        })
        
        request.symbologies = [.EAN13]
        self.requests = [request]
    }
    
    func detected(barcode value: String) {
        if detected != value {
            detected = value
            let valid = value.isISBN13
            if valid {
                lookup(isbn: value)
            }
            
            DispatchQueue.main.async {
                let key = valid ? "candidate.lookup.valid" : "candidate.lookup.invalid"
                self.barcodeView.stringValue = key.localized(with: ["search": value])
            }
        }
    }
    
    
    func lookup(isbn: String) {
        lookup?.cancel()
        if let collection = application.viewModel?.collection {
            lookup = application.lookupManager.lookup(ean: isbn, collection: collection) { (session, state) in
                self.lookupUpdate(session: session, state: state)
            }
        }
    }
    
    func lookupUpdate(session: LookupSession, state: LookupSession.State) {
        switch state {
        case .starting:
            barcodeView.stringValue = "candidate.lookup.start".localized(with: ["search": session.search])
            lookupSpinner.startAnimation(self)
            lookupSpinner.isHidden = false
            candidates.removeAll()
            candidatesTable.isHidden = true
            candidatesTable.reloadData()
            addButton.isEnabled = false
            
        case .done:
            barcodeView.stringValue = "candidate.found".localized(count: candidates.count)
            lookupSpinner.stopAnimation(self)
            lookupSpinner.isHidden = true
            
        case .foundCandidate(let candidate):
            let rows = IndexSet(integer: candidates.count)
            candidates.append(candidate)
            candidatesTable.isHidden = false
            candidatesTable.insertRows(at: rows, withAnimation: .slideDown)
            if candidatesTable.selectedRow == -1 {
                candidatesTable.selectRowIndexes(rows, byExtendingSelection: false)
            }
            addButton.isEnabled = true
            
        default:
            break
        }
    }
    
    
    @IBAction func doTest(_ sender: Any) {
        detected(barcode: "9781408832240")
        lookup(isbn: "9781408832240")
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

extension ScannerViewController: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return candidates.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let view = tableView.makeView(withIdentifier: ScannerViewController.candidateViewID, owner: self) as! ScannerCandidateCell
        let candidate = candidates[row]
        view.setup(with: candidate)
        
        return view
    }
}
