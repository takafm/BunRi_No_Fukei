//
//  ViewController.swift
//  BunRiCamera
//
//  Created by 大山 貴史 on 2020/09/22.
//  Copyright © 2020 大山 貴史. All rights reserved.
//

import UIKit
import AVFoundation
import Vision
import CoreML

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var confidenceLabel: UILabel!
    @IBOutlet weak var shutterView: UIView!
    
    var confidenceVal: Float?
    var streamImage: CIImage?
    var captureLayer: AVCaptureVideoPreviewLayer?
    var session: AVCaptureSession!
    
    private let CAPTURE_THRESH: Float = 0.98 // スクショを発動するConfidenceの閾値

    override func viewDidLoad() {
        super.viewDidLoad()
        cameraView.layer.cornerRadius = 18
        shutterView.layer.cornerRadius = 18
        self.shutterView.alpha = 0
        setupCamera()
    }

    override func viewDidLayoutSubviews() {
        captureLayer?.frame = cameraView.bounds
    }

    func setupCamera() {
        self.session = AVCaptureSession()
        captureLayer = AVCaptureVideoPreviewLayer(session: session)
        cameraView.layer.addSublayer(captureLayer!)

        guard let device = AVCaptureDevice.default(for: .video) else { return }
        guard let input = try? AVCaptureDeviceInput(device: device) else { return }
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera"))
        session.addInput(input)
        session.addOutput(output)
        session.startRunning()
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if connection.videoOrientation != .portrait {
            connection.videoOrientation = .portrait
            return
        }
        guard let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        self.streamImage = CIImage(cvImageBuffer: buffer)
        bunriDetection()
    }
    
    @IBAction func butonTupped(_ sender: Any) {
        guard let result = self.resultLabel.text else { return }
        guard let confidence = self.confidenceVal else { return }
        self.fireScreenShot(compText: "\(result)\n\(confidence * 100) %")
    }
    
    private func bunriDetection() {
        guard let model = try? VNCoreMLModel(for: BunRiClassifier().model) else { return }
            let request = VNCoreMLRequest(model: model) { request, error in
                guard let results = request.results as? [VNClassificationObservation] else { return }
                guard let mostConfidentResult = results.first else { return }

                DispatchQueue.main.async {
                    self.resultLabel.text = mostConfidentResult.identifier
                    let confidence = mostConfidentResult.confidence
                    self.confidenceVal = confidence
                    self.confidenceLabel.text = "Confidence: \(confidence * 100) %"
                    if confidence >= self.CAPTURE_THRESH {
                        self.fireScreenShot(compText: "\(mostConfidentResult.identifier)\n\(confidence * 100) %")
                    }
                }
            }
        
        guard let queryImage = self.streamImage else { return }
        let requestHandler = VNImageRequestHandler(ciImage: queryImage, options: [:])
        guard ( try? requestHandler.perform([request]) ) != nil else { return }
    }
    
    private func fireScreenShot(compText: String = "") {
        self.shutterView.alpha = 1
        
        self.session.stopRunning()
        
        if let image = self.streamImage {
            let context = CIContext(options: nil)
            if let cgimage = context.createCGImage(image, from: image.extent) {
                if let compImage = self.compositeUIImage(baseCGImage: cgimage, text: compText) {
                    UIImageWriteToSavedPhotosAlbum(compImage, nil, nil, nil)
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.shutterView.alpha = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.session.startRunning()
        }
    }
    
    private func compositeUIImage(baseCGImage: CGImage, text: String = "") -> UIImage? {
        let uiimage = UIImage(cgImage: baseCGImage)
        let font = UIFont.boldSystemFont(ofSize: 100)
        
        UIGraphicsBeginImageContext(uiimage.size)
        let rect = CGRect(x: 0, y: 0, width: uiimage.size.width, height: uiimage.size.height)
        uiimage.draw(in: rect)
                
        let textRect = CGRect(x:0, y:0, width:1080, height:500)
        let textStyle = NSMutableParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        let textFontAttributes = [
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.foregroundColor: UIColor.white,
            NSAttributedString.Key.backgroundColor: UIColor(red: 0, green: 0, blue: 0, alpha: 0.5),
            NSAttributedString.Key.paragraphStyle: textStyle
        ]
        
        text.draw(in: textRect, withAttributes: textFontAttributes)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}
