import Flutter
import UIKit
import DeepAR
import AVFoundation

public class SwiftDeepArPlugin: NSObject, FlutterPlugin, FlutterTexture,  DeepARDelegate {
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
    private var arView: ARView!
    
    private var cameraController: CameraController!
    
    
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
            let key = registrar?.lookupKey(forAsset: effect)
            let topPath = Bundle.main.path(forResource: key, ofType: nil)
            deepAR.switchEffect(withSlot: "effect", path: topPath)
        case "start_recording_video":
            arView.startVideoRecording(withOutputWidth: 720, outputHeight: 1280)
            deepAR.startVideoRecording(withOutputWidth: 720, outputHeight: 1280)
        case "stop_recording_video":
            deepAR.finishVideoRecording()
        case "flip_camera":
            cameraController.position = cameraController.position == .back ? .front : .back
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
        self.deepAR.changeLiveMode(true);
        
        //self.deepAR.initializeOffscreen(withWidth: 720, height: 1280);
        
        cameraController = CameraController()
        cameraController.preset = AVCaptureSession.Preset.hd1920x1080
        cameraController.videoOrientation = .portrait
        
        cameraController.deepAR = self.deepAR
        self.deepAR.videoRecordingWarmupEnabled = false;
        
        self.arView = self.deepAR.createARView(withFrame: CGRect(x: 0, y: 0, width: 1080, height: 1920)) as? ARView
        
        cameraController.startCamera()
        
        
    }
    
    public func didStartVideoRecording() {
        print("VIDEO START")
    }
    
    public func didFinishVideoRecording(_ videoFilePath: String!) {
        print(videoFilePath)
        print("VIDEO STOP")
    }
    
    
    public func didInitialize() {
        print("DEEPAR INIT")
        deepAR.showStats(true)
        
        deepAR.startCapture(withOutputWidth: 1080, outputHeight: 1920, subframe: CGRect(x: 0, y: 0, width: 1, height: 1))
    }
    
    ///Frames available should be triggered when enque camera frames are available
    public func frameAvailable(_ sampleBuffer: CMSampleBuffer!) {
        //print("frameAvailable")
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
    
    
    private func setUpCamera(result: @escaping FlutterResult){
        let size = ["width": 1080.0, "height": 1920.0]
        let answer: [String : Any?] = ["textureId": textureId, "size": size]
        result(answer)
        
    }
}
