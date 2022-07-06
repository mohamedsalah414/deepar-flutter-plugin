package com.deepar.deep_ar;

import android.app.Activity;
import android.util.Log;
import android.util.Size;

import androidx.annotation.NonNull;
import androidx.camera.core.CameraSelector;
import androidx.camera.core.ImageAnalysis;
import androidx.camera.core.ImageProxy;
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

public class CameraXHandler implements MethodChannel.MethodCallHandler {
    CameraXHandler(Activity activity, long textureId, DeepAR deepAR, CameraResolutionPreset cameraResolutionPreset) {
        this.activity = activity;
        this.deepAR = deepAR;
        this.textureId = textureId;
        this.resolutionPreset = cameraResolutionPreset;
    }

    final private Activity activity;
    final private DeepAR deepAR;
    private final long textureId;
    private ProcessCameraProvider processCameraProvider;
    private ByteBuffer[] buffers;
    private int currentBuffer = 0;
    private static final int NUMBER_OF_BUFFERS = 2;
    private final CameraResolutionPreset resolutionPreset;


    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        if (call.method.equals(MethodStrings.startCamera)) {
            startNative(call, result);
        }
    }

    private void startNative(MethodCall call, MethodChannel.Result result) {
        final ListenableFuture<ProcessCameraProvider> future = ProcessCameraProvider.getInstance(activity);
        Executor executor = ContextCompat.getMainExecutor(activity);

        int width = resolutionPreset.getWidth();
        int height = resolutionPreset.getHeight();
        buffers = new ByteBuffer[NUMBER_OF_BUFFERS];
        for (int i = 0; i < NUMBER_OF_BUFFERS; i++) {
            buffers[i] = ByteBuffer.allocateDirect
                    (CameraResolutionPreset.P1920x1080.getWidth()
                            * CameraResolutionPreset.P1920x1080.getHeight() * 3);
            buffers[i].order(ByteOrder.nativeOrder());
            buffers[i].position(0);
        }

        future.addListener(new Runnable() {
            @Override
            public void run() {
                try {
                    processCameraProvider = future.get();
                    Size cameraResolution = new Size(width, height);
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
                                    Log.d("FRAMES__", width + " * " + height);
                                    deepAR.receiveFrame(buffers[currentBuffer],
                                            image.getWidth(), image.getHeight(),
                                            image.getImageInfo().getRotationDegrees(),
                                            true,
                                            DeepARImageFormat.YUV_420_888,
                                            image.getPlanes()[1].getPixelStride()
                                    );

                                } catch (Exception e) {
                                    e.printStackTrace();
                                    Log.e("ERRRR", "" + e);
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
                    processCameraProvider.unbindAll();

                    processCameraProvider.bindToLifecycle((LifecycleOwner) activity,
                            CameraSelector.DEFAULT_FRONT_CAMERA, imageAnalysis);
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
