package com.example.analysis_ai;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.Service;
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
import android.util.DisplayMetrics;
import android.util.Log;

import androidx.core.app.NotificationCompat;

import java.io.File;
import java.io.IOException;

public class ScreenRecordService extends Service {
    private static final String TAG = "ScreenRecordService";
    private MediaProjection mediaProjection;
    private MediaRecorder mediaRecorder;
    private VirtualDisplay virtualDisplay;
    private static final int NOTIFICATION_ID = 123;
    private static final String CHANNEL_ID = "screen_record_channel";
    private int left, top, width, height;
    private int densityDpi;
    private String outputPath;
    private HandlerThread handlerThread;
    private Handler handler;

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    @Override
    public void onCreate() {
        super.onCreate();
        createNotificationChannel();
        handlerThread = new HandlerThread("ScreenRecordThread");
        handlerThread.start();
        handler = new Handler(handlerThread.getLooper());
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        int resultCode = intent.getIntExtra("resultCode", -1);
        Intent data = intent.getParcelableExtra("data");
        left = intent.getIntExtra("left", 0);
        top = intent.getIntExtra("top", 0);
        width = intent.getIntExtra("width", 1080);
        height = intent.getIntExtra("height", 1920);

        DisplayMetrics metrics = getResources().getDisplayMetrics();
        densityDpi = metrics.densityDpi;

        startForeground(NOTIFICATION_ID, createNotification());
        startRecording(resultCode, data);
        return START_STICKY;
    }

    private void startRecording(int resultCode, Intent data) {
        try {
            // Initialize MediaRecorder
            mediaRecorder = new MediaRecorder();
            mediaRecorder.setVideoSource(MediaRecorder.VideoSource.SURFACE);
            mediaRecorder.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4);
            mediaRecorder.setVideoEncoder(MediaRecorder.VideoEncoder.H264);
            mediaRecorder.setVideoSize(width, height);
            mediaRecorder.setVideoFrameRate(30);
            mediaRecorder.setVideoEncodingBitRate(5 * 1000 * 1000);
            outputPath = getOutputFile().getAbsolutePath();
            mediaRecorder.setOutputFile(outputPath);
            mediaRecorder.prepare();

            // Initialize MediaProjection
            MediaProjectionManager projectionManager =
                    (MediaProjectionManager) getSystemService(MEDIA_PROJECTION_SERVICE);
            mediaProjection = projectionManager.getMediaProjection(resultCode, data);

            if (mediaProjection == null) {
                Log.e(TAG, "MediaProjection is null");
                stopSelf();
                return;
            }

            // Register callback for MediaProjection
            MediaProjection.Callback callback = new MediaProjection.Callback() {
                @Override
                public void onStop() {
                    Log.d(TAG, "MediaProjection stopped");
                    stopRecording();
                    stopSelf();
                }
            };
            mediaProjection.registerCallback(callback, handler);

            virtualDisplay = mediaProjection.createVirtualDisplay(
                    "ScreenRecorder",
                    width, height, densityDpi,
                    DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
                    mediaRecorder.getSurface(),
                    null, null
            );

            mediaRecorder.start();
            Log.d(TAG, "Recording started, output: " + outputPath);
        } catch (IOException e) {
            Log.e(TAG, "Error starting recording: " + e.getMessage());
            e.printStackTrace();
            stopSelf();
        }
    }

    private File getOutputFile() {
        File dir = new File(getExternalFilesDir(null), "ScreenRecords");
        if (!dir.exists()) dir.mkdirs();
        return new File(dir, "recording_" + System.currentTimeMillis() + ".mp4");
    }

    private Notification createNotification() {
        return new NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle("Screen Recording")
                .setContentText("Recording in progress")
                .setSmallIcon(android.R.drawable.ic_media_play)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .build();
    }

    private void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(
                    CHANNEL_ID,
                    "Screen Recording Service",
                    NotificationManager.IMPORTANCE_LOW
            );
            NotificationManager manager = getSystemService(NotificationManager.class);
            if (manager != null) {
                manager.createNotificationChannel(channel);
            }
        }
    }

    @Override
    public void onDestroy() {
        stopRecording();
        if (handlerThread != null) {
            handlerThread.quitSafely();
        }
        super.onDestroy();
    }

    private void stopRecording() {
        if (mediaRecorder != null) {
            try {
                mediaRecorder.stop();
                Log.d(TAG, "MediaRecorder stopped, output: " + outputPath);
            } catch (IllegalStateException e) {
                Log.e(TAG, "Error stopping MediaRecorder: " + e.getMessage());
                e.printStackTrace();
            }
            mediaRecorder.reset();
            mediaRecorder.release();
            mediaRecorder = null;
        }

        if (virtualDisplay != null) {
            virtualDisplay.release();
            virtualDisplay = null;
        }

        if (mediaProjection != null) {
            // Note: unregisterCallback requires API 31+; we'll stop directly
            mediaProjection.stop();
            mediaProjection = null;
        }

        stopForeground(true);

        // Broadcast the output path
        Intent intent = new Intent("com.example.analysis_ai.RECORDING_FINISHED");
        intent.putExtra("outputPath", outputPath);
        sendBroadcast(intent);
    }
}