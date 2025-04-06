package com.example.analysis_ai;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

import android.content.BroadcastReceiver;
import android.content.ContentValues;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.media.projection.MediaProjectionManager;
import android.os.Build;
import android.os.Bundle;
import android.provider.MediaStore;
import android.util.Log;
import android.net.Uri;
import java.io.FileInputStream;
import java.io.OutputStream;
import java.io.File;              // Added import
public class MainActivity extends FlutterActivity {
    private static final String TAG = "MainActivity";
    private static final String RECORDING_CHANNEL = "com.example.analysis_ai/recording";
    private static final String PLATFORM_CHANNEL = "com.example.analysis_ai/platform";
    private static final String MEDIASTORE_CHANNEL = "com.example.analysis_ai/mediastore";
    private static final int SCREEN_RECORD_REQUEST_CODE = 123;
    private MediaProjectionManager projectionManager;
    private int left, top, width, height;
    private String lastOutputPath;
    private MethodChannel.Result pendingResult;
    private BroadcastReceiver recordingReceiver;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        projectionManager = (MediaProjectionManager) getSystemService(MEDIA_PROJECTION_SERVICE);

        recordingReceiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                lastOutputPath = intent.getStringExtra("outputPath");
                Log.d(TAG, "Broadcast received, outputPath: " + lastOutputPath);
                if (pendingResult != null) {
                    pendingResult.success(lastOutputPath);
                    Log.d(TAG, "Sent outputPath to Flutter: " + lastOutputPath);
                    pendingResult = null;
                } else {
                    Log.w(TAG, "No pending result to send outputPath");
                }
            }
        };
        IntentFilter filter = new IntentFilter("com.example.analysis_ai.RECORDING_FINISHED");
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(recordingReceiver, filter, Context.RECEIVER_NOT_EXPORTED);
        } else {
            registerReceiver(recordingReceiver, filter);
        }
    }

    @Override
    public void configureFlutterEngine(FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), RECORDING_CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    if (call.method.equals("startScreenRecording")) {
                        left = call.argument("left");
                        top = call.argument("top");
                        width = call.argument("width");
                        height = call.argument("height");
                        startScreenRecording();
                        result.success(true);
                    } else if (call.method.equals("stopScreenRecording")) {
                        Log.d(TAG, "Stopping screen recording service");
                        Intent stopIntent = new Intent(this, ScreenRecordService.class);
                        stopService(stopIntent);
                        pendingResult = result;
                    } else {
                        result.notImplemented();
                    }
                });

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), PLATFORM_CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    if (call.method.equals("getSdkVersion")) {
                        result.success(Build.VERSION.SDK_INT);
                    } else {
                        result.notImplemented();
                    }
                });

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), MEDIASTORE_CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    if (call.method.equals("saveVideoToGallery")) {
                        String sourcePath = call.argument("sourcePath");
                        String fileName = call.argument("fileName");
                        String relativePath = call.argument("relativePath");
                        try {
                            String savedPath = saveVideoToMediaStore(sourcePath, fileName, relativePath);
                            result.success(savedPath);
                        } catch (Exception e) {
                            Log.e(TAG, "Error saving to Media Store: " + e.getMessage());
                            result.error("MEDIA_STORE_ERROR", e.getMessage(), null);
                        }
                    } else {
                        result.notImplemented();
                    }
                });
    }

    private String saveVideoToMediaStore(String sourcePath, String fileName, String relativePath) throws Exception {
        File sourceFile = new File(sourcePath);
        if (!sourceFile.exists()) {
            throw new Exception("Source file does not exist: " + sourcePath);
        }

        ContentValues values = new ContentValues();
        values.put(MediaStore.Video.Media.DISPLAY_NAME, fileName);
        values.put(MediaStore.Video.Media.MIME_TYPE, "video/mp4");
        values.put(MediaStore.Video.Media.RELATIVE_PATH, "Movies/" + relativePath);
        values.put(MediaStore.Video.Media.IS_PENDING, 1);

        Uri uri = getContentResolver().insert(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, values);
        if (uri == null) throw new Exception("Failed to create Media Store entry");

        try (OutputStream out = getContentResolver().openOutputStream(uri);
             FileInputStream in = new FileInputStream(sourceFile)) {
            byte[] buffer = new byte[1024];
            int len;
            while ((len = in.read(buffer)) != -1) {
                out.write(buffer, 0, len);
            }
            out.flush();
        }

        values.clear();
        values.put(MediaStore.Video.Media.IS_PENDING, 0);
        getContentResolver().update(uri, values, null, null);

        String finalPath = "Movies/" + relativePath + "/" + fileName;
        Log.d(TAG, "Video saved to Media Store: " + finalPath);
        return finalPath; // Return relative path for Flutter to display
    }

    private void startScreenRecording() {
        startActivityForResult(
                projectionManager.createScreenCaptureIntent(),
                SCREEN_RECORD_REQUEST_CODE
        );
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == SCREEN_RECORD_REQUEST_CODE && resultCode == RESULT_OK) {
            Intent serviceIntent = new Intent(this, ScreenRecordService.class);
            serviceIntent.putExtra("resultCode", resultCode);
            serviceIntent.putExtra("data", data);
            serviceIntent.putExtra("left", left);
            serviceIntent.putExtra("top", top);
            serviceIntent.putExtra("width", width);
            serviceIntent.putExtra("height", height);
            startService(serviceIntent);
        }
    }

    @Override
    protected void onDestroy() {
        if (recordingReceiver != null) {
            unregisterReceiver(recordingReceiver);
        }
        super.onDestroy();
    }
}