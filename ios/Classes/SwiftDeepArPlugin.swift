import Flutter
import UIKit
import DeepAR
import AVFoundation

public class SwiftDeepArPlugin: NSObject, FlutterPlugin, FlutterTexture, AVCaptureVideoDataOutputSampleBufferDelegate, DeepARDelegate {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "deep_ar", binaryMessenger: registrar.messenger())
        let instance = SwiftDeepArPlugin(registrar.textures())
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    let registry: FlutterTextureRegistry
    var textureId: Int64!
    var latestBuffer: CVImageBuffer!
    var analyzeMode: Int
    var analyzing: Bool
    var deepAr: DeepAR!
    var session: AVCaptureSession?
    //let output = AVCapturePhotoOutput()
    let videoOutput = AVCaptureVideoDataOutput()
    let previewLayer = AVCaptureVideoPreviewLayer()
    
    private let shutterButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        button.layer.cornerRadius = 50
        button.layer.borderWidth = 3
        button.layer.borderColor = UIColor.white.cgColor
        return button
    }()
    
    init(_ registry: FlutterTextureRegistry) {
        self.registry = registry
        analyzeMode = 0
        analyzing = false
        super.init()
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if ("check_version" == call.method) {
            result("iOS " + UIDevice.current.systemVersion)
        }
        
        if ("create_surface" == call.method) {
            textureId = registry.register(self)
            //registry.textureFrameAvailable(textureId)
            //deepAr.changeLiveMode(true)
            
            self.deepAr = DeepAR()
            self.deepAr.delegate = self
            deepAr.setLicenseKey("53de9b68021fd5be051ddd80c8d1aee5653eda7cabcd58776c1a96e5027f4a8c78d4946795ccd944")
            deepAr.initialize()
            
            checkCameraPermission()
            
            result(textureId)
        }
        
    }
    
    private func checkCameraPermission(){
        switch AVCaptureDevice.authorizationStatus(for: .video){
            
        case .notDetermined:
            // Request Permission
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard granted else {
                    return
                }
                
                DispatchQueue.main.async {
                    self?.setUpCamera()
                }
            }
        case .restricted:
            break
        case .denied:
            break
        case .authorized:
            setUpCamera()
        @unknown default:
            break
        }
    }
    
    private func setUpCamera(){
        let session = AVCaptureSession()
        if let device = AVCaptureDevice.default(for: .video)
        {
            do {
                session.beginConfiguration()
                 let input = try AVCaptureDeviceInput(device: device)
                if session.canAddInput(input){
                    session.addInput(input)
                }
                
//                if session.canAddOutput(output){
//                    session.addOutput(output)
//                }
                
                //previewLayer.videoGravity = .resizeAspectFill
                //previewLayer.session = session
                
                
                        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
                        videoOutput.alwaysDiscardsLateVideoFrames = true
                        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)
                if session.canAddOutput(videoOutput){
                    session.addOutput(videoOutput)
                }
                session.commitConfiguration()
                session.startRunning()
                
                self.session = session
            } catch  {
                print(error)
            }
        }
    }
    
     
    public func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
        if latestBuffer == nil {
            return nil
        }
        return Unmanaged<CVPixelBuffer>.passRetained(latestBuffer)
    }
    
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        //registry.textureFrameAvailable(textureId)
        //deepAr.processFrame(CMSampleBufferGetImageBuffer(sampleBuffer), mirror: true)
    }
    
    public func frameAvailable(_ sampleBuffer: CMSampleBuffer!) {
        print("DEEP_AR_FRAMES")
    }
}
