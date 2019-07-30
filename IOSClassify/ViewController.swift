//
//  ViewController.swift
//  IOSClassify
//
//  Created by Jeff Heaton on 7/30/19.
//  Copyright © 2019 Jeff Heaton. All rights reserved.
//

// import necessary packages
import UIKit
import AVFoundation
import Vision

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    // Create classification and confidence.
    let label: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Label"
        label.font = label.font.withSize(30)
        return label
    }()
    
    override func viewDidLoad() {
        // Call parent.
        super.viewDidLoad()
        
        // establish the capture session and add the label
        setupCaptureSession()
        view.addSubview(label)
        setupLabel()
    }
    
    override func didReceiveMemoryWarning() {
        // Call parent.
        super.didReceiveMemoryWarning()
        
        // Dispose of any resources that can be recreated.
    }
    
    func setupCaptureSession() {
        // New capture session.
        let captureSession = AVCaptureSession()
        
        // Find cameras.
        let availableDevices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back).devices
        
        do {
            // select a camera.
            if let captureDevice = availableDevices.first {
                captureSession.addInput(try AVCaptureDeviceInput(device: captureDevice))
            }
        } catch {
            // Error.
            print(error.localizedDescription)
        }
        
        // Setup an output to stream video to.
        let captureOutput = AVCaptureVideoDataOutput()
        captureSession.addOutput(captureOutput)
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.frame
        view.layer.addSublayer(previewLayer)
        
        // Start the capture session.
        captureOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.startRunning()
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Load our CoreML model
        guard let model = try? VNCoreMLModel(for: mobilenet().model) else { return }
        
        // Inference with CoreML
        let request = VNCoreMLRequest(model: model) { (finishedRequest, error) in
            
            // Get the inference results.
            guard let results = finishedRequest.results as? [VNClassificationObservation] else { return }
            
            // Get the highest confidence classification.
            guard let Observation = results.first else { return }
            
            // Create the label text output string.
            let predclass = "\(Observation.identifier)"
            let predconfidence = String(format: "%.02f", Observation.confidence * 100)
            
            // Set the label text.
            DispatchQueue.main.async(execute: {
                self.label.text = "\(predclass) \(predconfidence)%"
            })
        }
        
        // Create a Core Video pixel buffer. This is an image buffer that holds
        // pixels in memory.
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // Execute the request.
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }
    
    func setupLabel() {
        // Center the output label.
        label.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        // Link the label to 50 pixels from the bottom.
        label.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50).isActive = true
    }
}
