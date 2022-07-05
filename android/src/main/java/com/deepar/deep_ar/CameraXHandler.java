package com.deepar.deep_ar;

import android.app.Activity;
import android.graphics.SurfaceTexture;
import android.util.Log;
import android.util.Size;
import android.view.Surface;

import androidx.annotation.NonNull;
import androidx.camera.core.Camera;
import androidx.camera.core.CameraSelector;
import androidx.camera.core.ImageAnalysis;
import androidx.camera.core.ImageProxy;
import androidx.camera.core.Preview;
import androidx.camera.core.SurfaceRequest;
import androidx.camera.lifecycle.ProcessCameraProvider;
import androidx.core.content.ContextCompat;
import androidx.lifecycle.LifecycleOwner;

import com.google.common.util.concurrent.ListenableFuture;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Executor;

import ai.deepar.ar.CameraResolutionPreset;
import ai.deepar.ar.DeepAR;
import ai.deepar.ar.DeepARImageFormat;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.view.TextureRegistry;

public class CameraXHandler implements MethodChannel.MethodCallHandler {
    CameraXHandler(Activity activity, TextureRegistry textureRegistry, DeepAR deepARR, Surface globalSurface, long textureId){
        mActivity = activity;
        //mTextureRegistry = textureRegistry;
        deepAR = deepARR;
        surface = globalSurface;
        this.textureId = textureId;
    }

    final Activity mActivity;
    //final TextureRegistry mTextureRegistry;
     ProcessCameraProvider processCameraProvider;
     //TextureRegistry.SurfaceTextureEntry textureEntry;
     private DeepAR deepAR;
     private Camera camera;
     private long textureId;
    Preview.SurfaceProvider surfaceProvider;
    Preview preview;
    private Surface surface;

    private ByteBuffer[] buffers;
    private int currentBuffer = 0;
    private static final int NUMBER_OF_BUFFERS=2;

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
if (call.method.equals("startCamera")){
    startNative(call, result);
}
    }
    boolean sendFrames = true;

    private void startNative(MethodCall call, MethodChannel.Result result) {
        final ListenableFuture<ProcessCameraProvider> future = ProcessCameraProvider.getInstance(mActivity);
        Executor executor = ContextCompat.getMainExecutor(mActivity);
        CameraResolutionPreset cameraResolutionPreset = CameraResolutionPreset.P1920x1080;
        buffers = new ByteBuffer[NUMBER_OF_BUFFERS];
        for (int i = 0; i < NUMBER_OF_BUFFERS; i++) {
            buffers[i] = ByteBuffer.allocateDirect(cameraResolutionPreset.getWidth() * cameraResolutionPreset.getHeight() * 3);
            buffers[i].order(ByteOrder.nativeOrder());
            buffers[i].position(0);
        }

        future.addListener(new Runnable() {
            @Override
            public void run() {
                try {
                    processCameraProvider = future.get();
                    Size cameraResolution = new Size(cameraResolutionPreset.getWidth(), cameraResolutionPreset.getHeight());
                    ImageAnalysis.Analyzer analyzer = new ImageAnalysis.Analyzer() {
                        @Override
                        public void analyze(@NonNull ImageProxy image) {
                            byte[] byteData;
                            ByteBuffer yBuffer = image.getPlanes()[0].getBuffer();
                            ByteBuffer uBuffer = image.getPlanes()[1].getBuffer();
                            ByteBuffer vBuffer = image.getPlanes()[2].getBuffer();

                            int ySize = yBuffer.remaining();
                            int uSize = uBuffer.remaining();
                            int vSize = vBuffer.remaining();

                            byteData = new byte[ySize + uSize + vSize];

                            //U and V are swapped
                            yBuffer.get(byteData, 0, ySize);
                            vBuffer.get(byteData, ySize, vSize);
                            uBuffer.get(byteData, ySize + vSize, uSize);

                            buffers[currentBuffer].put(byteData);
                            buffers[currentBuffer].position(0);
                            if (deepAR != null) {
                                try {

                                    Log.d("FRAMES", "frames__analyze: ");
                                    deepAR.receiveFrame(buffers[currentBuffer],
                                            image.getWidth(), image.getHeight(),
                                            image.getImageInfo().getRotationDegrees(),
                                            true,
                                            DeepARImageFormat.YUV_420_888,
                                            image.getPlanes()[1].getPixelStride()
                                    );

                                }catch (Exception e){
                                    e.printStackTrace();
                                    Log.e("ERRRR", ""+e );
                                }

                            }
                            currentBuffer = (currentBuffer + 1) % NUMBER_OF_BUFFERS;
                            image.close();
                        }
                    };



                    ImageAnalysis imageAnalysis = new ImageAnalysis.Builder()
                            .setTargetResolution(cameraResolution)
                            .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                            .build();

                    imageAnalysis.setAnalyzer(executor, analyzer);

                    camera = processCameraProvider.bindToLifecycle((LifecycleOwner) mActivity, CameraSelector.DEFAULT_FRONT_CAMERA, imageAnalysis);

                    result.success(textureId);



                } catch (ExecutionException e) {
                    e.printStackTrace();
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }

            }
        }, executor);

    }
}
