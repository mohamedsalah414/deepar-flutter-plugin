package com.deepar.deep_ar;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import android.Manifest;
import android.app.Activity;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.SurfaceTexture;
import android.media.Image;
import android.os.Build;
import android.util.Log;
import android.view.Surface;
import android.widget.Toast;

import java.util.ArrayList;
import java.util.Map;

import ai.deepar.ar.ARErrorType;
import ai.deepar.ar.AREventListener;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

import io.flutter.plugin.common.PluginRegistry;
import io.flutter.view.TextureRegistry;
import ai.deepar.ar.DeepAR;

/**
 * DeepArPlugin
 */
public class DeepArPlugin implements FlutterPlugin, AREventListener, ActivityAware, PluginRegistry.RequestPermissionsResultListener {
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


    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {

        onActivityAttached(binding);
    }


    private void onActivityAttached(@NonNull ActivityPluginBinding binding) {
        activity = binding.getActivity();
        deepArEffects = new DeepArEffects();
        setDeepArMethodChannel();
        binding.addRequestPermissionsResultListener(this);
    }

    private boolean checkPermission(){
        if (ContextCompat.checkSelfPermission(activity, Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED ||
                ContextCompat.checkSelfPermission(activity, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED ||
                ContextCompat.checkSelfPermission(activity, Manifest.permission.WRITE_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED) {

            ActivityCompat.requestPermissions(activity, new String[]{Manifest.permission.CAMERA, Manifest.permission.WRITE_EXTERNAL_STORAGE, Manifest.permission.RECORD_AUDIO},
                    1);
            return false;
        } else {
            // Permission has already been granted
            return true;
        }
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
            case MethodStrings.checkAllPermission: // Check permission
                boolean permission = checkPermission();
                result.success(permission);
                break;
            case MethodStrings.initialize: // Initialize
                String licenseKey = (String) arguments.get(MethodStrings.licenseKey);
                String resolution = (String) arguments.get(MethodStrings.resolution);
                int width = ((Number) arguments.get("width")).intValue();
                int height = ((Number) arguments.get("height")).intValue();
                Log.d(TAG, "licenseKey = " + licenseKey);
                final boolean success = initializeDeepAR(licenseKey, width, height);
                if (success) {
                    setCameraXChannel();
                }
                result.success(true);
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

    private void setCameraXChannel() {
        cameraXChannel = new MethodChannel(flutterPlugin.getBinaryMessenger(), MethodStrings.cameraXChannel);
        CameraXHandler handler = new CameraXHandler(activity,
                textureId, deepAR);
        cameraXChannel.setMethodCallHandler(handler);
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {

    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        onActivityAttached(binding);
    }

    @Override
    public void onDetachedFromActivity() {
        flutterPlugin = null;
    }


    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        flutterPlugin = flutterPluginBinding;
    }


    private boolean initializeDeepAR(String licenseKey, int width, int height) {
        try {
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

    @Override
    public boolean onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        Log.d(TAG, "onRequestPermissionsResult: "+requestCode);
        return false;
    }
}
