package com.example.analysis_ai;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.hardware.display.DisplayManager;
import android.hardware.display.VirtualDisplay;
import android.media.MediaRecorder;
import android.media.projection.MediaProjection;
import android.media.projection.MediaProjectionManager;
import android.os.Build;
import android.os.Handler;
import android.os.HandlerThread;
import android.os.IBinder;

import androidx.core.app.NotificationCompat;

import java.io.IOException;

public class ScreenRecorderService extends Service {
    public static final String EXTRA_RESULT_CODE = "resultCode";
    public static final String EXTRA_RESULT_DATA = "resultData";
    public static final int NOTIFICATION_ID = 1;
    public static final String CHANNEL_ID = "ScreenRecordingChannel";
    private MediaRecorder mediaRecorder;
    private MediaProjection mediaProjection;
    private VirtualDisplay virtualDisplay;
    private String outputPath;
    private HandlerThread handlerThread;
    private Handler handler;
    private MediaProjection.Callback projectionCallback;
    private boolean isRecording = false; // Track recording state

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (intent == null || !intent.hasExtra("outputPath")) {
            return START_NOT_STICKY;
        }
        outputPath = intent.getStringExtra("outputPath");
        int resultCode = intent.getIntExtra(EXTRA_RESULT_CODE, -1);
        Intent resultData = intent.getParcelableExtra(EXTRA_RESULT_DATA);

        startForegroundNotification();
        if (!setupMediaRecorder()) {
            stopSelf();
            return START_NOT_STICKY;
        }
        startRecording(resultCode, resultData);
        return START_STICKY;
    }

    private void startForegroundNotification() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(
                    CHANNEL_ID,
                    "Screen Recording",
                    NotificationManager.IMPORTANCE_LOW
            );
            NotificationManager manager = (NotificationManager) getSystemService(NOTIFICATION_SERVICE);
            if (manager != null) {
                manager.createNotificationChannel(channel);
            }
        }

        Notification notification = new NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle("Recording Screen")
                .setContentText("Screen recording is in progress")
                .setSmallIcon(android.R.drawable.ic_media_play)
                .build();

        startForeground(NOTIFICATION_ID, notification);
    }

    private boolean setupMediaRecorder() {
        mediaRecorder = new MediaRecorder();
        try {
            mediaRecorder.setVideoSource(MediaRecorder.VideoSource.SURFACE);
            mediaRecorder.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4);
            mediaRecorder.setOutputFile(outputPath);
            mediaRecorder.setVideoEncoder(MediaRecorder.VideoEncoder.H264);
            mediaRecorder.setVideoEncodingBitRate(512 * 1000);
            mediaRecorder.setVideoFrameRate(30);
            mediaRecorder.setVideoSize(1280, 720); // Adjust as needed
            mediaRecorder.prepare();
            return true;
        } catch (IOException e) {
            e.printStackTrace();
            mediaRecorder.release(); // Release if setup fails
            mediaRecorder = null;
            return false;
        }
    }

    private void startRecording(int resultCode, Intent resultData) {
        MediaProjectionManager projectionManager = (MediaProjectionManager) getSystemService(Context.MEDIA_PROJECTION_SERVICE);
        mediaProjection = projectionManager.getMediaProjection(resultCode, resultData);

        // Set up a handler thread for the callback
        handlerThread = new HandlerThread("MediaProjectionCallbackThread");
        handlerThread.start();
        handler = new Handler(handlerThread.getLooper());

        // Register the callback
        projectionCallback = new MediaProjection.Callback() {
            @Override
            public void onStop() {
                stopRecording();
                stopSelf();
            }
        };
        mediaProjection.registerCallback(projectionCallback, handler);

        virtualDisplay = mediaProjection.createVirtualDisplay(
                "ScreenRecorder",
                1280, 720, 1,
                DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
                mediaRecorder.getSurface(),
                null,
                null
        );
        try {
            mediaRecorder.start();
            isRecording = true; // Mark as recording
        } catch (IllegalStateException e) {
            e.printStackTrace();
            stopRecording(); // Clean up if start fails
        }
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        stopRecording();
        stopForeground(true);

        // Clean up the callback and handler thread
        if (mediaProjection != null && projectionCallback != null) {
            mediaProjection.unregisterCallback(projectionCallback);
        }
        if (handlerThread != null) {
            handlerThread.quitSafely();
        }
    }

    private void stopRecording() {
        if (mediaRecorder != null && isRecording) {
            try {
                mediaRecorder.stop();
            } catch (RuntimeException e) {
                e.printStackTrace(); // Log if stop fails (e.g., recording wasn’t started)
            }
            isRecording = false;
        }
        if (mediaRecorder != null) {
            try {
                mediaRecorder.reset();
                mediaRecorder.release();
            } catch (IllegalStateException e) {
                e.printStackTrace(); // Log if reset fails
            }
            mediaRecorder = null;
        }
        if (virtualDisplay != null) {
            virtualDisplay.release();
            virtualDisplay = null;
        }
        if (mediaProjection != null) {
            mediaProjection.stop();
            mediaProjection = null;
        }
    }
}