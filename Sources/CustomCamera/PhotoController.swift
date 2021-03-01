//
//  File.swift
//  
//
//  Created by Macintosh on 25/01/21.
//

import UIKit
import AVFoundation

public class PhotoController: UIViewController {
    private var captureSession : AVCaptureSession!
    
    private var backCamera : AVCaptureDevice!
    private var frontCamera : AVCaptureDevice!
    private var backInput : AVCaptureInput!
    private var frontInput : AVCaptureInput!
    
    private var previewLayer : AVCaptureVideoPreviewLayer!
    
    private var videoOutput : AVCaptureVideoDataOutput!
    
    private var takePicture = false
    private var cameraType: CameraType = .other
    
    public enum CameraType {
        case selfie(frame: UIImage)
        case idCard(frame: UIImage)
        case other
    }
    
    private lazy var captureView: UIButton = {
        let view = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        view.layer.cornerRadius = 25
        view.addTarget(self, action: #selector(onTapCapture), for: .touchUpInside)
        return view
    }()
    
    private var completion: ((UIImage)->Void)?
    
    public init(with type: CameraType, completion: ((UIImage)->Void)?) {
        super.init(nibName: nil, bundle: nil)
        
        self.cameraType = type
        self.completion = completion
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        navigationController?.navigationBar.isTranslucent = false
        if isModal {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Batal", style: .plain, target: self, action: #selector(onTapCancel))
        }
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkPermissions()
        setupAndStartCaptureSession()
    }
    
    @objc
    private func onTapCancel() {
        navigationController?.dismiss(animated: true, completion: { [weak self] in
            self?.stopCaptureSession()
        })
    }
    
    @objc
    private func onTapCapture() {
        takePicture = true
    }
    
    private func setupAndStartCaptureSession(){
        DispatchQueue.global(qos: .userInitiated).async{
            //init session
            self.captureSession = AVCaptureSession()
            //start configuration
            self.captureSession.beginConfiguration()

            //session specific configuration
            //before setting a session presets, we should check if the session supports it
            if self.captureSession.canSetSessionPreset(.photo) {
                self.captureSession.sessionPreset = .photo
            }
            self.captureSession.automaticallyConfiguresCaptureDeviceForWideColor = true

            //setup inputs
            self.setupInputs()
            
            DispatchQueue.main.async {
                //setup preview layer
                self.setupPreviewLayer()
            }
            
            //setup output
            self.setupOutput()
            
            //commit configuration
            self.captureSession.commitConfiguration()
            //start running it
            self.captureSession.startRunning()
        }
    }
    
    private func setupInputs(){
        switch cameraType {
        case .selfie:
            if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
                frontCamera = device
            } else {
                fatalError("no front camera")
            }
            guard let fInput = try? AVCaptureDeviceInput(device: frontCamera) else {
                fatalError("could not create input device from front camera")
            }
            frontInput = fInput
            if !captureSession.canAddInput(frontInput) {
                fatalError("could not add front camera input to capture session")
            }
            captureSession.addInput(frontInput)
        default:
            if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                backCamera = device
            } else {
                fatalError("no back camera")
            }
            guard let bInput = try? AVCaptureDeviceInput(device: backCamera) else {
                fatalError("could not create input device from back camera")
            }
            backInput = bInput
            if !captureSession.canAddInput(backInput) {
                fatalError("could not add back camera input to capture session")
            }
            captureSession.addInput(backInput)
        }
    }
    
    private func setupPreviewLayer(){
        view.addSubview(captureView)
        captureView.center = CGPoint(x: view.bounds.width/2, y: view.bounds.height-(25+8+view.safeAreaInsets.bottom))
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.bounds = view.layer.bounds
        previewLayer.position = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.insertSublayer(previewLayer, below: captureView.layer)
        switch cameraType {
        case .selfie(let frame),
             .idCard(let frame):
            let margin = 2*(25+8+view.safeAreaInsets.bottom)
            let image = UIImageView(image: frame)
            image.contentMode = .scaleAspectFit
            image.frame = CGRect(x: 0, y: 0, width: view.layer.frame.width, height: view.layer.frame.height-margin)
            view.insertSubview(image, belowSubview: captureView)
        default: break
        }
    }
    
    private func setupOutput(){
        videoOutput = AVCaptureVideoDataOutput()
        let videoQueue = DispatchQueue(label: "videoQueue", qos: .userInteractive)
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
        
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        } else {
            fatalError("could not add video output")
        }
        
        videoOutput.connections.first?.videoOrientation = .portrait
    }
    
    private func switchCameraInput() {
        captureSession.beginConfiguration()
        switch cameraType {
        case .selfie:
            captureSession.removeInput(frontInput)
            captureSession.addInput(backInput)
            videoOutput.connections.first?.isVideoMirrored = true
        default:
            captureSession.removeInput(backInput)
            captureSession.addInput(frontInput)
            videoOutput.connections.first?.isVideoMirrored = false
        }

        videoOutput.connections.first?.videoOrientation = .portrait

        captureSession.commitConfiguration()
    }
    
    private func checkPermissions() {
        let cameraAuthStatus =  AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        switch cameraAuthStatus {
          case .authorized:
            return
          case .denied:
            abort()
          case .notDetermined:
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler:
            { (authorized) in
              if(!authorized){
                abort()
              }
            })
          case .restricted:
            abort()
          @unknown default:
            fatalError()
        }
    }
    
    private func stopCaptureSession() {
        captureSession.stopRunning()
        if let inputs = captureSession.inputs as? [AVCaptureDeviceInput] {
            for input in inputs {
                captureSession.removeInput(input)
            }
        }
    }
}

extension PhotoController: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if takePicture {
            takePicture = false
            guard let cvBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                return
            }
            let context = CIContext()
            let ciImage = CIImage(cvImageBuffer: cvBuffer)
            let imageRect = CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(cvBuffer), height: CVPixelBufferGetHeight(cvBuffer))
            if let cgImage = context.createCGImage(ciImage, from: imageRect) {
                var image: UIImage
                switch cameraType {
                case .selfie:
                    image = UIImage(cgImage: cgImage, scale: UIScreen.main.scale, orientation: .upMirrored)
                default:
                    image = UIImage(cgImage: cgImage, scale: UIScreen.main.scale, orientation: .up)
                }
                DispatchQueue.main.async { [weak self] in
                    guard let `self` = self else { return }
                    let viewController = ResultController(with: image) { [weak self] image in
                        self?.completion?(image)
                    }
                    self.navigationController?.pushViewController(viewController, animated: true)
                    self.stopCaptureSession()
                }
            }
        }
    }
}
