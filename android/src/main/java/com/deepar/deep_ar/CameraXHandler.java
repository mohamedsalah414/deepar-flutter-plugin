package com.deepar.deep_ar;

import android.app.Activity;
import android.graphics.SurfaceTexture;
import android.util.Log;
import android.util.Size;

import androidx.annotation.NonNull;
import androidx.camera.core.Camera;
import androidx.camera.core.CameraSelector;
import androidx.camera.core.Preview;
import androidx.camera.lifecycle.ProcessCameraProvider;
import androidx.core.content.ContextCompat;
import androidx.lifecycle.LifecycleOwner;

import com.google.common.util.concurrent.ListenableFuture;

import java.util.concurrent.ExecutionException;
import java.util.concurrent.Executor;

import ai.deepar.ar.DeepAR;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.view.TextureRegistry;

public class CameraXHandler implements MethodChannel.MethodCallHandler {
    CameraXHandler(Activity activity, TextureRegistry textureRegistry, DeepAR deepARR){
        mActivity = activity;
        mTextureRegistry = textureRegistry;
        deepAR = deepARR;
    }

    final Activity mActivity;
    final TextureRegistry mTextureRegistry;
     ProcessCameraProvider processCameraProvider;
     TextureRegistry.SurfaceTextureEntry textureEntry;
     private DeepAR deepAR;
     private Camera camera;
    Preview.SurfaceProvider surfaceProvider;
    Preview preview;

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
if (call.method.equals("startCamera")){
    startNative(call, result);
}
    }
private int nativeGLTextureHandle = 0;
    private void startNative(MethodCall call, MethodChannel.Result result) {
        final ListenableFuture<ProcessCameraProvider> future = ProcessCameraProvider.getInstance(mActivity);
        Executor executor = ContextCompat.getMainExecutor(mActivity);

        future.addListener(new Runnable() {
            @Override
            public void run() {

                try {
                    processCameraProvider = future.get();
                    //textureEntry = mTextureRegistry.createSurfaceTexture();

                    // request the external gl texture from deepar
                    if(nativeGLTextureHandle == 0) {
                        nativeGLTextureHandle = deepAR.getExternalGlTexture();
                        Log.d("tag", "request new external GL texture");
                        //printEglState();
                    }

                    textureEntry = mTextureRegistry.registerSurfaceTexture(new SurfaceTexture(nativeGLTextureHandle));

                    //int surfaceProvider = Preview.SurfaceProvider;

                    surfaceProvider = new ArSurfaceProvider(mActivity, deepAR, textureEntry.surfaceTexture(), nativeGLTextureHandle);


                     preview = new Preview.Builder()
                            .build();
                    preview.setSurfaceProvider(surfaceProvider);

                    camera = processCameraProvider.bindToLifecycle((LifecycleOwner) mActivity, CameraSelector.DEFAULT_FRONT_CAMERA, preview);

                    result.success(textureEntry.id());



                } catch (ExecutionException e) {
                    e.printStackTrace();
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }

            }
        }, executor);

    }
}
