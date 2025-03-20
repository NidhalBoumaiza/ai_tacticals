package com.example.analysis_ai;

import android.content.Intent;
import android.media.projection.MediaProjectionManager;
import android.os.Build;
import android.os.Bundle;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.example.analysis_ai/screen_recorder";
    private static final int REQUEST_CODE_SCREEN_CAPTURE = 1001;
    private MethodChannel.Result result;
    private String outputPath;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        new MethodChannel(getFlutterEngine().getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    this.result = result;
                    if (call.method.equals("startRecording")) {
                        String outputPath = call.argument("outputPath");
                        if (outputPath == null) {
                            result.error("INVALID_ARGUMENT", "Output path is null", null);
                            return;
                        }
                        startScreenRecording(outputPath);
                    } else if (call.method.equals("stopRecording")) {
                        stopScreenRecording();
                    } else {
                        result.notImplemented();
                    }
                });
    }

    private void startScreenRecording(String outputPath) {
        MediaProjectionManager projectionManager = (MediaProjectionManager) getSystemService(MEDIA_PROJECTION_SERVICE);
        startActivityForResult(projectionManager.createScreenCaptureIntent(), REQUEST_CODE_SCREEN_CAPTURE);
        this.outputPath = outputPath;
    }

    private void stopScreenRecording() {
        Intent intent = new Intent(this, ScreenRecorderService.class);
        stopService(intent);
        if (result != null) {
            result.success(outputPath);
        }
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == REQUEST_CODE_SCREEN_CAPTURE) {
            if (resultCode == RESULT_OK) {
                Intent intent = new Intent(this, ScreenRecorderService.class);
                intent.putExtra(ScreenRecorderService.EXTRA_RESULT_CODE, resultCode);
                intent.putExtra(ScreenRecorderService.EXTRA_RESULT_DATA, data);
                intent.putExtra("outputPath", outputPath);
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    startForegroundService(intent);
                } else {
                    startService(intent);
                }
                if (result != null) {
                    result.success(null);
                }
            } else {
                if (result != null) {
                    result.error("PERMISSION_DENIED", "Screen recording permission denied", null);
                }
            }
        }
    }
}