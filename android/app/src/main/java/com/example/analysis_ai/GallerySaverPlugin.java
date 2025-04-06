package com.example.analysis_ai;

import android.content.ContentValues;
import android.content.Context;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.provider.MediaStore;
import androidx.annotation.NonNull;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import java.io.File;
import java.io.FileInputStream;
import java.io.OutputStream;

public class GallerySaverPlugin implements FlutterPlugin, MethodChannel.MethodCallHandler {
    private static final String CHANNEL = "com.example.analysis_ai/gallery_saver";
    private Context context;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPlugin.FlutterPluginBinding binding) {
        context = binding.getApplicationContext();
        MethodChannel channel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL);
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        if (call.method.equals("saveVideo")) {
            String path = call.argument("path");
            String albumName = call.argument("albumName");
            boolean toDcim = call.argument("toDcim");

            try {
                Uri uri = saveVideoToGallery(path, albumName, toDcim);
                result.success(uri != null);
            } catch (Exception e) {
                result.error("SAVE_VIDEO_ERROR", "Failed to save video: " + e.getMessage(), null);
            }
        } else {
            result.notImplemented();
        }
    }

    private Uri saveVideoToGallery(String filePath, String albumName, boolean toDcim) throws Exception {
        File file = new File(filePath);
        if (!file.exists()) {
            return null;
        }

        ContentValues values = new ContentValues();
        values.put(MediaStore.Video.Media.DISPLAY_NAME, file.getName());
        values.put(MediaStore.Video.Media.MIME_TYPE, "video/mp4");
        values.put(MediaStore.Video.Media.DATE_ADDED, System.currentTimeMillis() / 1000);
        values.put(MediaStore.Video.Media.DATE_TAKEN, System.currentTimeMillis());

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            String relativePath = toDcim ? Environment.DIRECTORY_DCIM : Environment.DIRECTORY_MOVIES + "/" + albumName;
            values.put(MediaStore.Video.Media.RELATIVE_PATH, relativePath);
            values.put(MediaStore.Video.Media.IS_PENDING, 1);
        } else {
            String directory = toDcim ? Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DCIM).getPath()
                    : Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MOVIES).getPath() + "/" + albumName;
            File dir = new File(directory);
            if (!dir.exists()) dir.mkdirs();
            File destFile = new File(dir, file.getName());
            file.renameTo(destFile);
            values.put(MediaStore.Video.Media.DATA, destFile.getAbsolutePath());
        }

        Uri uri = context.getContentResolver().insert(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, values);
        if (uri != null) {
            try {
                OutputStream out = context.getContentResolver().openOutputStream(uri);
                FileInputStream in = new FileInputStream(file);
                byte[] buffer = new byte[1024];
                int len;
                while ((len = in.read(buffer)) > 0) {
                    out.write(buffer, 0, len);
                }
                out.close();
                in.close();

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    values.clear();
                    values.put(MediaStore.Video.Media.IS_PENDING, 0);
                    context.getContentResolver().update(uri, values, null, null);
                }
            } catch (Exception e) {
                context.getContentResolver().delete(uri, null, null);
                return null;
            }
        }
        return uri;
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPlugin.FlutterPluginBinding binding) {
        // Cleanup if needed
    }
}