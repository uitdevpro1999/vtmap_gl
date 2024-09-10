package com.mapbox.mapboxgl;

import static io.flutter.plugin.common.PluginRegistry.Registrar;

import android.content.Context;

import com.viettel.vtmsdk.camera.CameraPosition;

import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;

import java.util.Map;
import java.util.concurrent.atomic.AtomicInteger;

public class MapboxMapFactory extends PlatformViewFactory {

  private final AtomicInteger mActivityState;
  private final Registrar mPluginRegistrar;

  public MapboxMapFactory(AtomicInteger state, Registrar registrar) {
    super(StandardMessageCodec.INSTANCE);
    mActivityState = state;
    mPluginRegistrar = registrar;
  }

  @Override
  public PlatformView create(Context context, int id, Object args) {
    Map<String, Object> params = (Map<String, Object>) args;
    final MapboxMapBuilder builder = new MapboxMapBuilder();

    Convert.interpretMapboxMapOptions(params.get("options"), builder);
    if (params.containsKey("initialCameraPosition")) {
      CameraPosition position = Convert.toCameraPosition(params.get("initialCameraPosition"));
      builder.setInitialCameraPosition(position);
    }

    if (params.containsKey("gpsControlEnable")) {
      Boolean gpsControlEnabled= (Boolean)params.get("gpsControlEnable");
      builder.setGPSControlEnable(gpsControlEnabled);
    }

    if (params.containsKey("mapTypeControlEnable")) {
      Boolean mapTypeControlEnabled= (Boolean)params.get("mapTypeControlEnable");
      builder.setMapTypeControlEnable(mapTypeControlEnabled);
    }

    return builder.build(id, context, mActivityState, mPluginRegistrar, (String) params.get("accessToken"));
  }
}
