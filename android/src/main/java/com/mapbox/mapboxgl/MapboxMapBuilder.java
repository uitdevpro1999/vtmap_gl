// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.mapbox.mapboxgl;

import android.content.Context;
import android.util.Log;
import android.view.Gravity;

import com.viettel.vtmsdk.camera.CameraPosition;
import com.viettel.vtmsdk.geometry.LatLngBounds;
import com.viettel.vtmsdk.maps.VTMapOptions;
import com.viettel.vtmsdk.maps.Style;

import io.flutter.plugin.common.PluginRegistry;

import java.util.concurrent.atomic.AtomicInteger;


class MapboxMapBuilder implements MapboxMapOptionsSink {
  public final String TAG = getClass().getSimpleName();
  private final VTMapOptions options = new VTMapOptions()
    .textureMode(true);
    //.attributionEnabled(true)
   // .logoEnabled(false)
    //.attributionEnabled(false);
  private boolean trackCameraPosition = false;
  private boolean myLocationEnabled = true;
  private int myLocationTrackingMode = 0;
  private int myLocationRenderMode = 0;
  private String styleString = Style.MAPBOX_STREETS;
  private boolean gpsControlEnabled = true;
  private boolean mapTypeControlEnabled = true;
  private boolean logoEnabled = true;

  MapboxMapController build(
    int id, Context context, AtomicInteger state, PluginRegistry.Registrar registrar, String accessToken) {
    final MapboxMapController controller =
      new MapboxMapController(id, context, state, registrar, options, accessToken, styleString);
    controller.init();
    controller.setMyLocationEnabled(myLocationEnabled);
    controller.setMyLocationTrackingMode(myLocationTrackingMode);
    controller.setMyLocationRenderMode(myLocationRenderMode);
    controller.setTrackCameraPosition(trackCameraPosition);
    controller.setGPSControlEnable(gpsControlEnabled);
    controller.setMapTypeControlEnable(mapTypeControlEnabled);
    controller.setLogoEnable(logoEnabled);
    return controller;
  }

  public void setInitialCameraPosition(CameraPosition position) {
    options.camera(position);
  }

  @Override
  public void setCompassEnabled(boolean compassEnabled) {
    options.compassEnabled(compassEnabled);
  }

  @Override
  public void setCameraTargetBounds(LatLngBounds bounds) {
    Log.e(TAG, "setCameraTargetBounds is supported only after map initiated.");
    //throw new UnsupportedOperationException("setCameraTargetBounds is supported only after map initiated.");
    //options.latLngBoundsForCameraTarget(bounds);
  }

  @Override
  public void setStyleString(String styleString) {
    this.styleString = styleString;
    //options. styleString(styleString);
  }

  @Override
  public void setMinMaxZoomPreference(Float min, Float max) {
    if (min != null) {
      options.minZoomPreference(min);
    }
    if (max != null) {
      options.maxZoomPreference(max);
    }
  }

  @Override
  public void setTrackCameraPosition(boolean trackCameraPosition) {
    this.trackCameraPosition = trackCameraPosition;
  }

  @Override
  public void setRotateGesturesEnabled(boolean rotateGesturesEnabled) {
    options.rotateGesturesEnabled(rotateGesturesEnabled);
  }

  @Override
  public void setScrollGesturesEnabled(boolean scrollGesturesEnabled) {
    options.scrollGesturesEnabled(scrollGesturesEnabled);
  }

  @Override
  public void setTiltGesturesEnabled(boolean tiltGesturesEnabled) {
    options.tiltGesturesEnabled(tiltGesturesEnabled);
  }

  @Override
  public void setZoomGesturesEnabled(boolean zoomGesturesEnabled) {
    options.zoomGesturesEnabled(zoomGesturesEnabled);
  }

  @Override
  public void setMyLocationEnabled(boolean myLocationEnabled) {
    this.myLocationEnabled = myLocationEnabled;
  }

  @Override
  public void setMyLocationTrackingMode(int myLocationTrackingMode) {
    this.myLocationTrackingMode = myLocationTrackingMode;
  }

  @Override
  public void setMyLocationRenderMode(int myLocationRenderMode) {
    this.myLocationRenderMode = myLocationRenderMode;
  }

  @Override
  public void setGPSControlEnable(Boolean enable) {
    this.gpsControlEnabled = enable;
  }

  @Override
  public void setMapTypeControlEnable(Boolean enable) {
    this.mapTypeControlEnabled = enable;
  }

  @Override
  public void setLogoEnable(Boolean enable) {
    this.logoEnabled = enable;
  }

  public void setLogoViewMargins(int x, int y) {
        options.logoMargins(new int[] {
            (int) x, //left
            (int) 0, //top
            (int) 0, //right
            (int) y, //bottom
    });
  }

  @Override
  public void setCompassGravity(int gravity) {
    switch(gravity){
      case 0:
        options.compassGravity(Gravity.TOP | Gravity.START);
        break;
      default:
      case 1:
        options.compassGravity(Gravity.TOP | Gravity.END);
        break;
      case 2:
        options.compassGravity(Gravity.BOTTOM | Gravity.START);
        break;
      case 3:
        options.compassGravity(Gravity.BOTTOM | Gravity.END);
        break;
    }
  }

  @Override
  public void setCompassViewMargins(int x, int y) {
    switch(options.getCompassGravity())
    {
      case Gravity.TOP | Gravity.START:
        options.compassMargins(new int[] {(int) x, (int) y, 0, 0});
        break;
      default:
      case Gravity.TOP | Gravity.END:
        options.compassMargins(new int[] {0, (int) y, (int) x, 0});
        break;
      case Gravity.BOTTOM | Gravity.START:
        options.compassMargins(new int[] {(int) x, 0, 0, (int) y});
        break;
      case Gravity.BOTTOM | Gravity.END:
        options.compassMargins(new int[] {0, 0, (int) x, (int) y});
        break;
    }
  }

  @Override
  public void setAttributionButtonMargins(int x, int y) {
    options.attributionMargins(new int[] {
            (int) x, //left
            (int) 0, //top
            (int) 0, //right
            (int) y, //bottom
    });
  }
}
