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
    var deepAR: DeepAR!
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
        if("check_all_permission" == call.method){
            let isGranted:Bool = checkCameraPermission()
            result(isGranted)
        }
        
        if ("create_surface" == call.method) {
            textureId = registry.register(self)
            
            setupDeepARCamera();
            setUpCamera(result: result)
            
        }
        
    }
    
    private func checkCameraPermission() -> Bool{
        var isGranted:Bool = false
        switch AVCaptureDevice.authorizationStatus(for: .video){
            
        case .notDetermined:
            // Request Permission
            AVCaptureDevice.requestAccess(for: .video) { granted in
                guard granted else {
                    return
                }
                
                isGranted = true
                //                DispatchQueue.main.async {
                //                    self?.setUpCamera()
                //                }
            }
        case .restricted:
            break
        case .denied:
            break
        case .authorized:
            isGranted = true
        @unknown default:
            break
        }
        
        return isGranted
    }
    
    private func setupDeepARCamera(){
        deepAR = DeepAR();
        self.deepAR.delegate = self
        self.deepAR.setLicenseKey("38c170bb360fff2913731fdb0bb17a6257d85e6240d53aeb53a997886698ab4cb13a8b90736684ae")
        self.deepAR.changeLiveMode(true);
        self.deepAR.initializeOffscreen(withWidth: 1920, height: 1080);
    }
    
    private func setUpCamera(result: @escaping FlutterResult){
        let session = AVCaptureSession()
        let position = AVCaptureDevice.Position.front
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
        {
            do {
                session.beginConfiguration()
                let input = try AVCaptureDeviceInput(device: device)
                if session.canAddInput(input){
                    session.addInput(input)
                }
                                
                videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
                videoOutput.alwaysDiscardsLateVideoFrames = true
                videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main);
                
                if session.canAddOutput(videoOutput){
                    session.addOutput(videoOutput)
                }
                
                for connection in videoOutput.connections {
                    
                    connection.videoOrientation = .portrait
                    if position == .front && connection.isVideoMirroringSupported {
                        connection.isVideoMirrored = true
                    }
                }
                session.commitConfiguration()
                session.startRunning()
                self.session = session
                let demensions = CMVideoFormatDescriptionGetDimensions(device.activeFormat.formatDescription)
                let width = Double(demensions.height)
                let height = Double(demensions.width)
                let size = ["width": width, "height": height]
                let answer: [String : Any?] = ["textureId": textureId, "size": size]
                result(answer)
            } catch  {
                print(error)
            }
        }
    }
    public func faceTracked(_ faceData: MultiFaceData) {
        print("Face tracked");
    }
    public func didInitialize() {
        print("is initialized");
        self.deepAR.startCapture(withOutputWidth: 1920, outputHeight: 1080, subframe: CGRect(x: 0,y: 0,width: 1,height: 1))
    }

    

    ///Frames output from AvCaptureSession
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
       
        deepAR.enqueueCameraFrame(sampleBuffer, mirror: false);
    }
    ///Frames available should be triggered when enque camera frames are available
    public func frameAvailable(_ sampleBuffer: CMSampleBuffer!) {
        print("DEEPAR frames availble");
        //assign the lastest pixel buffer
        latestBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        ///update preview in flutter
        registry.textureFrameAvailable(textureId)
    }
    
    public func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
        if latestBuffer == nil {
            return nil
        }
        return Unmanaged<CVPixelBuffer>.passRetained(latestBuffer)
    }
    
}
