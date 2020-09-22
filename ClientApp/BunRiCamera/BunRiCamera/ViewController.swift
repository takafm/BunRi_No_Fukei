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

    var streamImage: CIImage?
    var captureLayer: AVCaptureVideoPreviewLayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }

    override func viewDidLayoutSubviews() {
        captureLayer?.frame = cameraView.bounds
    }

    func setupCamera() {
        let session = AVCaptureSession()
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

//    func faceDetection(_ buffer: CVImageBuffer) {
//        let request = VNDetectFaceRectanglesRequest { (request, error) in
//            guard let results = request.results as? [VNFaceObservation] else { return }
//            if let image = self.ciImage, let result = results.first {
//                let face = self.getFaceCGImage(image: image, face: result)
//                if let cg = face {
//                    self.showPreview(cgImage: cg)
//                    self.scanImage(cgImage: cg)
//                }
//            }
//        }
//
//        let handler = VNImageRequestHandler(cvPixelBuffer: buffer, options: [:])
//        try? handler.perform([request])
//    }
//
//    func getFaceCGImage(image: CIImage, face: VNFaceObservation) -> CGImage? {
//        let imageSize = image.extent.size
//
//        let box = face.boundingBox.scaledForCropping(to: imageSize)
//        guard image.extent.contains(box) else {
//            return nil
//        }
//
//        let size = CGFloat(300.0)
//
//        let transform = CGAffineTransform(
//            scaleX: size / box.size.width,
//            y: size / box.size.height
//        )
//        let faceImage = image.cropped(to: box).transformed(by: transform)
//
//        let ctx = CIContext()
//        guard let cgImage = ctx.createCGImage(faceImage, from: faceImage.extent) else {
//            assertionFailure()
//            return nil
//        }
//        return cgImage
//    }
//
//    private func showPreview(cgImage: CGImage) {
//        let uiImage = UIImage(cgImage: cgImage)
//        DispatchQueue.main.async {
//            self.faceImageView.image = uiImage
//        }
//    }
    
    private func bunriDetection() {
        guard let model = try? VNCoreMLModel(for: BunRiClassifier().model) else { return }
            let request = VNCoreMLRequest(model: model) { request, error in
                guard let results = request.results as? [VNClassificationObservation] else { return }
                guard let mostConfidentResult = results.first else { return }

                DispatchQueue.main.async {
                    self.resultLabel.text = mostConfidentResult.identifier
                    self.confidenceLabel.text = "Confidence: \(mostConfidentResult.confidence * 100) %"
                }
            }
        
        guard let queryImage = self.streamImage else { return }
        let requestHandler = VNImageRequestHandler(ciImage: queryImage, options: [:])
        guard ( try? requestHandler.perform([request]) ) != nil else { return }
    }

//    func scanImage(cgImage: CGImage) {
//        let image = CIImage(cgImage: cgImage)
//
//        guard let model = try? VNCoreMLModel(for: BunRiClassifier().model) else { return }
//        let request = VNCoreMLRequest(model: model) { request, error in
//            guard let results = request.results as? [VNClassificationObservation] else { return }
//            guard let mostConfidentResult = results.first else { return }
//
//            DispatchQueue.main.async {
//                self.resultLabel.text = mostConfidentResult.identifier
//            }
//        }
//        let requestHandler = VNImageRequestHandler(ciImage: image, options: [:])
//        try? requestHandler.perform([request])
//    }
}


//extension CGRect {
//    func scaledForCropping(to size: CGSize) -> CGRect {
//        return CGRect(
//            x: self.origin.x * size.width,
//            y: self.origin.y * size.height,
//            width: (self.size.width * size.width),
//            height: (self.size.height * size.height)
//        )
//    }
//}
