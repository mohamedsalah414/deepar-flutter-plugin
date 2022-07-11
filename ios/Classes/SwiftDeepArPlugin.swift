import Flutter
import UIKit
import DeepAR
import AVFoundation

public class SwiftDeepArPlugin: NSObject, FlutterPlugin, FlutterTexture, AVCaptureVideoDataOutputSampleBufferDelegate, DeepARDelegate {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "deep_ar", binaryMessenger: registrar.messenger())
        let instance = SwiftDeepArPlugin(registrar.textures())
        registrar.addMethodCallDelegate(instance, channel: channel)
        instance.registrar = registrar
    }
    
    var registrar: FlutterPluginRegistrar? = nil
    let registry: FlutterTextureRegistry
    var textureId: Int64!
    var latestBuffer: CVImageBuffer!
    var deepAR: DeepAR!
    var session: AVCaptureSession?
    let videoOutput = AVCaptureVideoDataOutput()
    let previewLayer = AVCaptureVideoPreviewLayer()
    
    
    init(_ registry: FlutterTextureRegistry) {
        self.registry = registry
        super.init()
    }
    
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        
        let args = call.arguments as? [String : Any]
        
        switch call.method {
        case "check_all_permission":
            let isGranted:Bool = checkCameraPermission()
            result(isGranted)
        case "initialize":
            let licenseKey: String = args?["license_key"] as! String
            setupDeepARCamera(licenseKey: licenseKey)
            result("Initialized")
            
        case "start_camera":
            textureId = registry.register(self)
            setUpCamera(result: result)
        case "switch_effect":
            let effect:String = args?["effect"] as! String
            //            let key = registrar?.lookupKey(forAsset: "assets/effects/burning_effect.deepar")
            let key = registrar?.lookupKey(forAsset: effect)
            let topPath = Bundle.main.path(forResource: key, ofType: nil)
            deepAR.switchEffect(withSlot: "effect", path: topPath)
        case "start_recording_video":
            let width: Int32 = Int32(deepAR.renderingResolution.width)
            let height: Int32 =  Int32(deepAR.renderingResolution.height)
            deepAR.startVideoRecording(withOutputWidth: width, outputHeight: height)
        case "stop_recording_video":
            deepAR.finishVideoRecording()
        default:
            result("Failed to call iOS platform method")
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
    
    private func setupDeepARCamera(licenseKey: String) {
        self.deepAR = DeepAR();
        self.deepAR.setLicenseKey(licenseKey)
        self.deepAR.delegate = self
        self.deepAR.changeLiveMode(false);
        self.deepAR.initializeOffscreen(withWidth: 1080, height: 1920);
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
    
    public func didStartVideoRecording() {
        print("VIDEO START")
    }
    
    public func didFinishVideoRecording(_ videoFilePath: String!) {
        print(videoFilePath)
        print("VIDEO STOP")
    }
    
    
    ///Frames output from AvCaptureSession
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        deepAR.enqueueCameraFrame(sampleBuffer, mirror: false);
    }
    
    ///Frames available should be triggered when enque camera frames are available
    public func frameAvailable(_ sampleBuffer: CMSampleBuffer!) {
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
