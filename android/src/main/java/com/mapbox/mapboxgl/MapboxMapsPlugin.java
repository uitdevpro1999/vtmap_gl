package com.mapbox.mapboxgl;

import android.app.Activity;
import android.app.Application;
import android.os.Bundle;
import androidx.annotation.NonNull;

import java.util.concurrent.atomic.AtomicInteger;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.platform.PlatformViewRegistry;

public class MapboxMapsPlugin implements FlutterPlugin, ActivityAware, Application.ActivityLifecycleCallbacks {
  private MethodChannel methodChannel;
  private Activity activity;
  static final int CREATED = 1;
  static final int STARTED = 2;
  static final int RESUMED = 3;
  static final int PAUSED = 4;
  static final int STOPPED = 5;
  static final int DESTROYED = 6;
  private final AtomicInteger state = new AtomicInteger(0);
  private final int registrarActivityHashCode;

  // Constructor for the old API
  public MapboxMapsPlugin(PluginRegistry.Registrar registrar) {
    this.registrarActivityHashCode = registrar.activity().hashCode();
    this.activity = registrar.activity();
    registerWith(registrar);
  }

  // New API onAttachedToEngine
  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    methodChannel = new MethodChannel(binding.getBinaryMessenger(), "plugins.flutter.io/mapbox_gl");
    methodChannel.setMethodCallHandler(new GlobalMethodHandler());

    // Register the view factory
    PlatformViewRegistry registry = binding.getPlatformViewRegistry();
    registry.registerViewFactory("plugins.flutter.io/mapbox_gl", new MapboxMapFactory(state, binding.getApplicationContext()));
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    methodChannel.setMethodCallHandler(null);
  }

  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
    activity = binding.getActivity();
    binding.addActivityResultListener(this);
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
    // Not used
  }

  @Override
  public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
    onAttachedToActivity(binding);
  }

  @Override
  public void onDetachedFromActivity() {
    activity = null;
  }

  // Old API registerWith method
  public static void registerWith(PluginRegistry.Registrar registrar) {
    if (registrar.activity() == null) {
      return; // Plugin is foreground only
    }
    final MapboxMapsPlugin plugin = new MapboxMapsPlugin(registrar);
    registrar.activity().getApplication().registerActivityLifecycleCallbacks(plugin);
    registrar
            .platformViewRegistry()
            .registerViewFactory("plugins.flutter.io/mapbox_gl", new MapboxMapFactory(plugin.state, registrar));

    MethodChannel methodChannel = new MethodChannel(registrar.messenger(), "plugins.flutter.io/mapbox_gl");
    methodChannel.setMethodCallHandler(new GlobalMethodHandler(registrar));
  }

  // Activity Lifecycle Callbacks
  @Override
  public void onActivityCreated(Activity activity, Bundle savedInstanceState) {
    if (activity.hashCode() != registrarActivityHashCode) {
      return;
    }
    state.set(CREATED); // CREATED
  }

  @Override
  public void onActivityStarted(Activity activity) {
    if (activity.hashCode() != registrarActivityHashCode) {
      return;
    }
    state.set(STARTED); // STARTED
  }

  @Override
  public void onActivityResumed(Activity activity) {
    if (activity.hashCode() != registrarActivityHashCode) {
      return;
    }
    state.set(RESUMED); // RESUMED
  }

  @Override
  public void onActivityPaused(Activity activity) {
    if (activity.hashCode() != registrarActivityHashCode) {
      return;
    }
    state.set(PAUSED); // PAUSED
  }

  @Override
  public void onActivityStopped(Activity activity) {
    if (activity.hashCode() != registrarActivityHashCode) {
      return;
    }
    state.set(STOPPED); // STOPPED
  }

  @Override
  public void onActivitySaveInstanceState(Activity activity, Bundle outState) {
  }

  @Override
  public void onActivityDestroyed(Activity activity) {
    if (activity.hashCode() != registrarActivityHashCode) {
      return;
    }
    state.set(DESTROYED); // DESTROYED
  }
}