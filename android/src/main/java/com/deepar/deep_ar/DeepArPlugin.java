package com.deepar.deep_ar;

import androidx.annotation.NonNull;

import android.app.Activity;
import android.graphics.Bitmap;
import android.graphics.SurfaceTexture;
import android.media.Image;
import android.util.Log;
import android.view.Surface;

import java.util.Collections;
import java.util.HashMap;
import java.util.Map;

import ai.deepar.ar.ARErrorType;
import ai.deepar.ar.AREventListener;
import ai.deepar.ar.CameraResolutionPreset;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

import io.flutter.view.TextureRegistry;
import ai.deepar.ar.DeepAR;

/**
 * DeepArPlugin
 */
public class DeepArPlugin implements FlutterPlugin, AREventListener, ActivityAware {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private MethodChannel cameraXChannel, channel;

    private final String TAG = "DEEP_AR_LOGS";
    private Activity activity;
    private DeepAR deepAR;
    private Surface surface;
    private long textureId;
    private DeepArEffects deepArEffects;
    private FlutterPluginBinding flutterPlugin;
    private SurfaceTexture tempSurfaceTexture;

    private CameraResolutionPreset resolutionPreset;


    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {

        activity = binding.getActivity();
        deepArEffects = new DeepArEffects();
        setDeepArMethodChannel();
    }

    private void setDeepArMethodChannel() {
        channel = new MethodChannel(flutterPlugin.getBinaryMessenger(), MethodStrings.generalChannel);
        channel.setMethodCallHandler(new MethodCallHandler() {
            @Override
            public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
                handleMethods(call, result);
            }
        });
    }

    private void handleMethods(MethodCall call, Result result) {
        Map<String, Object> arguments = (Map<String, Object>) call.arguments;

        switch (call.method) {
            case MethodStrings.initialize: // Initialize
                String licenseKey = (String) arguments.get(MethodStrings.licenseKey);
                String resolution = (String) arguments.get(MethodStrings.resolution);

                if(resolution.equals("veryHigh"))
                    resolutionPreset = CameraResolutionPreset.P1920x1080;
                 else if(resolution.equals("high"))
                    resolutionPreset = CameraResolutionPreset.P1280x720;
                 else if(resolution.equals("medium"))
                    resolutionPreset = CameraResolutionPreset.P640x480;
                 else
                    resolutionPreset = CameraResolutionPreset.P640x360;

                Log.d(TAG, "licenseKey = " + licenseKey);
                final boolean success = initializeDeepAR(licenseKey, resolutionPreset);
                if (success) {
                    setCameraXChannel(resolutionPreset);
                }
                result.success("" + resolutionPreset.getWidth() + " " + resolutionPreset.getHeight());
                break;

            case MethodStrings.switchEffect: // Switch Effect
                int effectIndex = ((Number) arguments.get(MethodStrings.effect)).intValue();
                deepAR.switchEffect("effect", deepArEffects.getFilterPath(effectIndex));
                result.success("Effect Changed");
                break;

            case MethodStrings.startRecordingVideo:
                String filePath = ((String) arguments.get("file_path")).toString();
                deepAR.startVideoRecording(filePath);
                break;

            case MethodStrings.stopRecordingVideo:
                deepAR.stopVideoRecording();
                break;
        }
    }

    private void setCameraXChannel(CameraResolutionPreset resolutionPreset) {
        cameraXChannel = new MethodChannel(flutterPlugin.getBinaryMessenger(), MethodStrings.cameraXChannel);
        final CameraXHandler handler = new CameraXHandler(activity,
                textureId, deepAR, resolutionPreset);
        cameraXChannel.setMethodCallHandler(handler);
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {

    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {

    }



    @Override
    public void onDetachedFromActivity() {
        flutterPlugin = null;
    }


    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        flutterPlugin = flutterPluginBinding;
    }


    private boolean initializeDeepAR(String licenseKey, CameraResolutionPreset resolutionPreset) {
        try {

            int width = resolutionPreset.getWidth();
            int height = resolutionPreset.getHeight();
            deepAR = new DeepAR(activity);
            deepAR.setLicenseKey(licenseKey);
            deepAR.initialize(activity, this);
            deepAR.changeLiveMode(true);

            TextureRegistry.SurfaceTextureEntry entry = flutterPlugin.getTextureRegistry().createSurfaceTexture();
            tempSurfaceTexture = entry.surfaceTexture();
            tempSurfaceTexture.setDefaultBufferSize(width, height);
            surface = new Surface(tempSurfaceTexture);
            deepAR.setRenderSurface(surface, width, height);
            textureId = entry.id();

            return true;
        } catch (Exception e) {
            Log.e(TAG, "ERROR" + e);
            return false;
        }

    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
        cameraXChannel.setMethodCallHandler(null);
    }

    @Override
    public void screenshotTaken(Bitmap bitmap) {

    }

    @Override
    public void videoRecordingStarted() {

    }

    @Override
    public void videoRecordingFinished() {

    }

    @Override
    public void videoRecordingFailed() {

    }

    @Override
    public void videoRecordingPrepared() {

    }

    @Override
    public void shutdownFinished() {

    }

    @Override
    public void initialized() {
        Log.d(TAG, "initialized : DEEP_AR");
    }

    @Override
    public void faceVisibilityChanged(boolean b) {

    }

    @Override
    public void imageVisibilityChanged(String s, boolean b) {

    }

    @Override
    public void frameAvailable(Image image) {
    }

    @Override
    public void error(ARErrorType arErrorType, String s) {

    }

    @Override
    public void effectSwitched(String s) {

    }
}
