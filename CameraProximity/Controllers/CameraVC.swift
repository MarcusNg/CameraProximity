//
//  CameraVC.swift
//  CameraProximity
//
//  Created by Marcus Ng on 12/25/17.
//  Copyright © 2017 Marcus Ng. All rights reserved.
//

import UIKit
import AVFoundation

class CameraVC: UIViewController {
    
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var captureImgView: UIImageView!
    @IBOutlet weak var savePhotoBtn: UIButton!
    @IBOutlet weak var reenableBtn: UIButton!
    
    var photoData: Data?
    var captureSession: AVCaptureSession!
    var cameraOutput: AVCapturePhotoOutput!
    var previewLayer: AVCaptureVideoPreviewLayer!
//    var flashControlState: FlashState = .off
    
    override func viewDidLoad() {
        super.viewDidLoad()
        savePhotoBtn.isEnabled = false
        reenableBtn.isEnabled = false
        setProximitySensorEnabled(true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        previewLayer.frame = cameraView.bounds
    }
    
    override func viewWillAppear(_ animated: Bool) {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = AVCaptureSession.Preset.hd1920x1080
        
        let backCamera = AVCaptureDevice.default(for: AVMediaType.video)
        
        do {
            // Input
            let input = try AVCaptureDeviceInput(device: backCamera!)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            
            // Output
            cameraOutput = AVCapturePhotoOutput()
            
            if captureSession.canAddOutput(cameraOutput) {
                captureSession.addOutput(cameraOutput!)
                
                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
                previewLayer.videoGravity = AVLayerVideoGravity.resizeAspect
                previewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
                
                cameraView.layer.addSublayer(previewLayer!)
                captureSession.startRunning()
            }
            
        } catch {
            debugPrint(error)
        }
    }

    @IBAction func reenableBtnPressed(_ sender: Any) {
        setProximitySensorEnabled(true)
        reenableBtn.isEnabled = false
    }
    
    @IBAction func photoBtnPressed(_ sender: Any) {
        savePhotoBtn.isEnabled = false
        // Save photo (bug: photos save in landscape)
        let newImage = UIImage(cgImage: (captureImgView.image?.cgImage)!, scale: 0.8, orientation: .up)
        let imageData = UIImagePNGRepresentation(newImage)
        let compressedImage = UIImage(data: imageData!)
        
        UIImageWriteToSavedPhotosAlbum(compressedImage!, nil, nil, nil)
        
        let alert = UIAlertController(title: "Saved", message: "Your image has been saved", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func proximityChanged(_ notification: Notification) {
        if (notification.object as? UIDevice) != nil {
            captureImage()
        }
    }
    
    // Proximity Sensor
    func setProximitySensorEnabled(_ enabled: Bool) {
        let device = UIDevice.current
        device.isProximityMonitoringEnabled = enabled
        if device.isProximityMonitoringEnabled {
            NotificationCenter.default.addObserver(self, selector: #selector(proximityChanged), name: .UIDeviceProximityStateDidChange, object: device)
        } else {
            NotificationCenter.default.removeObserver(self, name: .UIDeviceProximityStateDidChange, object: nil)
        }
    }
    
    func captureImage() {
        
        let settings = AVCapturePhotoSettings()
        settings.previewPhotoFormat = settings.embeddedThumbnailPhotoFormat
        
//        if flashControlState == .off {
//            settings.flashMode = .off
//        } else {
//            settings.flashMode = .on
//        }
        
        cameraOutput.capturePhoto(with: settings, delegate: self)
        
        savePhotoBtn.isEnabled = true
        reenableBtn.isEnabled = true
        setProximitySensorEnabled(false)
    }
    
}

extension CameraVC: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            debugPrint(error)
        } else {
            photoData = photo.fileDataRepresentation()
            
            let image = UIImage(data: photoData!)
            self.captureImgView.image = image
        }
    }
}
