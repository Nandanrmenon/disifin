package com.nahnah.disifin;

import android.content.Intent;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MusicActivity extends FlutterActivity {
    private static final String CHANNEL = "com.nahnah.disifin/audio";

    @Override
    public void configureFlutterEngine(FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler(
                        (call, result) -> {
                            Intent intent = new Intent(this, MediaPlaybackService.class);
                            switch (call.method) {
                                case "play":
                                    String url = call.argument("url");
                                    intent.setAction("PLAY");
                                    intent.putExtra("url", url);
                                    startService(intent);
                                    result.success(null);
                                    break;
                                case "pause":
                                    intent.setAction("PAUSE");
                                    startService(intent);
                                    result.success(null);
                                    break;
                                case "stop":
                                    intent.setAction("STOP");
                                    startService(intent);
                                    result.success(null);
                                    break;
                                case "next":
                                    intent.setAction("NEXT");
                                    startService(intent);
                                    result.success(null);
                                    break;
                                case "previous":
                                    intent.setAction("PREVIOUS");
                                    startService(intent);
                                    result.success(null);
                                    break;
                                default:
                                    result.notImplemented();
                                    break;
                            }
                        }
                );
    }
}
