package com.example.analysis_ai;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.media.projection.MediaProjectionManager;
import android.os.Build; // Add this import
import android.os.Bundle;
import android.util.Log;

public class MainActivity extends FlutterActivity {
    private static final String TAG = "MainActivity";
    private static final String CHANNEL = "com.example.analysis_ai/recording";
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
                Log.d(TAG, "Received output path: " + lastOutputPath);
                if (pendingResult != null) {
                    pendingResult.success(lastOutputPath);
                    pendingResult = null;
                }
            }
        };
        IntentFilter filter = new IntentFilter("com.example.analysis_ai.RECORDING_FINISHED");
        // Use RECEIVER_NOT_EXPORTED for internal app broadcasts
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(recordingReceiver, filter, Context.RECEIVER_NOT_EXPORTED);
        } else {
            registerReceiver(recordingReceiver, filter);
        }
    }

    @Override
    public void configureFlutterEngine(FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    if (call.method.equals("startScreenRecording")) {
                        left = call.argument("left");
                        top = call.argument("top");
                        width = call.argument("width");
                        height = call.argument("height");
                        startScreenRecording();
                        result.success(true);
                    } else if (call.method.equals("stopScreenRecording")) {
                        Intent stopIntent = new Intent(this, ScreenRecordService.class);
                        stopService(stopIntent);
                        pendingResult = result;
                    } else {
                        result.notImplemented();
                    }
                });
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