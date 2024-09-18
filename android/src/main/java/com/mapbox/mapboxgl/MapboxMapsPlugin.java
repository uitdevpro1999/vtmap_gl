package com.mapbox.mapboxgl;

import android.app.Activity;
import android.app.Application;
import android.os.Bundle;

import java.util.concurrent.atomic.AtomicInteger;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;

/**
 * Plugin for controlling a set of MapboxMap views to be shown as overlays on top of the Flutter
 * view. The overlay should be hidden during transformations or while Flutter is rendering on top of
 * the map. A Texture drawn using MapboxMap bitmap snapshots can then be shown instead of the
 * overlay.
 */
public class MapboxMapsPlugin implements FlutterPlugin, ActivityAware, Application.ActivityLifecycleCallbacks {
  static final int CREATED = 1;
  static final int STARTED = 2;
  static final int RESUMED = 3;
  static final int PAUSED = 4;
  static final int STOPPED = 5;
  static final int DESTROYED = 6;

  private final AtomicInteger state = new AtomicInteger(0);
  private int registrarActivityHashCode;
  private MethodChannel methodChannel;

  // Đăng ký với API cũ
  public static void registerWith(PluginRegistry.Registrar registrar) {
    if (registrar.activity() == null) {
      return; // Không có activity, dừng lại
    }
    final MapboxMapsPlugin plugin = new MapboxMapsPlugin();
    plugin.registrarActivityHashCode = registrar.activity().hashCode();
    registrar.activity().getApplication().registerActivityLifecycleCallbacks(plugin);

    registrar.platformViewRegistry().registerViewFactory("plugins.flutter.io/mapbox_gl", new MapboxMapFactory(plugin.state, registrar));

    // Khởi tạo MethodChannel
    plugin.setupChannel(registrar.messenger());
  }

  // Đăng ký với API mới
  @Override
  public void onAttachedToEngine(FlutterPlugin.FlutterPluginBinding binding) {
    setupChannel(binding.getBinaryMessenger());
  }

  private void setupChannel(BinaryMessenger messenger) {
    methodChannel = new MethodChannel(messenger, "plugins.flutter.io/mapbox_gl");
    methodChannel.setMethodCallHandler(new GlobalMethodHandler());
  }

  @Override
  public void onDetachedFromEngine(FlutterPlugin.FlutterPluginBinding binding) {
    methodChannel.setMethodCallHandler(null);
  }

  @Override
  public void onAttachedToActivity(ActivityPluginBinding binding) {
    this.registrarActivityHashCode = binding.getActivity().hashCode();
    binding.addActivityResultListener(this);
    binding.addRequestPermissionsResultListener(this);
    binding.getLifecycle().addObserver(this);
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
    // Xử lý khi tách activity cho thay đổi cấu hình
  }

  @Override
  public void onReattachedToActivityForConfigChanges(ActivityPluginBinding binding) {
    this.registrarActivityHashCode = binding.getActivity().hashCode();
  }

  @Override
  public void onDetachedFromActivity() {
    // Dọn dẹp khi tách activity
  }

  // Các phương thức vòng đời Activity
  @Override
  public void onActivityCreated(Activity activity, Bundle savedInstanceState) {
    if (activity.hashCode() != registrarActivityHashCode) {
      return;
    }
    state.set(CREATED);
  }

  @Override
  public void onActivityStarted(Activity activity) {
    if (activity.hashCode() != registrarActivityHashCode) {
      return;
    }
    state.set(STARTED);
  }

  @Override
  public void onActivityResumed(Activity activity, Bundle savedInstanceState) {
    if (activity.hashCode() != registrarActivityHashCode) {
      return;
    }
    state.set(RESUMED);
  }

  @Override
  public void onActivityPaused(Activity activity) {
    if (activity.hashCode() != registrarActivityHashCode) {
      return;
    }
    state.set(PAUSED);
  }

  @Override
  public void onActivityStopped(Activity activity) {
    if (activity.hashCode() != registrarActivityHashCode) {
      return;
    }
    state.set(STOPPED);
  }

  @Override
  public void onActivitySaveInstanceState(Activity activity, Bundle outState) {
    // Không cần xử lý
  }

  @Override
  public void onActivityDestroyed(Activity activity) {
    if (activity.hashCode() != registrarActivityHashCode) {
      return;
    }
    state.set(DESTROYED);
  }
}
