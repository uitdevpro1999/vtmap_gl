// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.mapbox.mapboxgl;

import android.widget.Toast;
import android.Manifest;
import android.app.Activity;
import android.app.Application;
import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.content.res.AssetFileDescriptor;
import android.content.res.AssetManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.PointF;
import android.graphics.RectF;
import android.location.Location;
import android.os.Build;
import android.os.Bundle;
import android.util.DisplayMetrics;

import androidx.annotation.NonNull;

import android.util.Log;
import android.view.Gravity;
import android.view.View;

import com.mapbox.api.directions.v5.DirectionsCriteria;
import com.mapbox.api.directions.v5.models.DirectionsResponse;
import com.mapbox.api.directions.v5.models.DirectionsRoute;
import com.mapbox.geojson.LineString;
import com.mapbox.geojson.Point;

import androidx.annotation.NonNull;

import com.google.gson.Gson;
import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.mapbox.android.core.location.LocationEngine;
import com.mapbox.android.core.location.LocationEngineCallback;
import com.mapbox.android.core.location.LocationEngineProvider;
import com.mapbox.android.core.location.LocationEngineResult;
import com.mapbox.android.telemetry.TelemetryEnabler;
import com.mapbox.geojson.Feature;
import com.mapbox.services.android.navigation.ui.v5.NavigationLauncher;
import com.mapbox.services.android.navigation.ui.v5.NavigationLauncherOptions;
import com.mapbox.services.android.navigation.ui.v5.camera.CameraUpdateMode;
import com.mapbox.services.android.navigation.ui.v5.camera.NavigationCameraUpdate;
import com.mapbox.services.android.navigation.ui.v5.route.OnRouteSelectionChangeListener;
import com.mapbox.services.android.navigation.v5.navigation.MapboxNavigation;
import com.mapbox.services.android.navigation.v5.navigation.MapboxNavigationOptions;
import com.mapbox.services.android.navigation.v5.navigation.NavigationRoute;
import com.viettel.vtmsdk.MapVT;
import com.viettel.vtmsdk.camera.CameraPosition;
import com.viettel.vtmsdk.camera.CameraUpdate;

import com.viettel.vtmsdk.camera.CameraUpdateFactory;
import com.viettel.vtmsdk.geometry.LatLng;
import com.viettel.vtmsdk.geometry.LatLngBounds;
import com.viettel.vtmsdk.geometry.LatLngQuad;
import com.viettel.vtmsdk.geometry.VisibleRegion;
import com.viettel.vtmsdk.location.LocationComponent;
import com.viettel.vtmsdk.location.LocationComponentOptions;
import com.viettel.vtmsdk.location.LocationComponentActivationOptions;
import com.viettel.vtmsdk.location.OnCameraTrackingChangedListener;
import com.viettel.vtmsdk.location.modes.CameraMode;
import com.viettel.vtmsdk.location.modes.RenderMode;
import com.viettel.vtmsdk.maps.MapView;
import com.viettel.vtmsdk.maps.VTMap;
import com.viettel.vtmsdk.maps.VTMapOptions;
import com.viettel.vtmsdk.maps.Projection;
import com.viettel.vtmsdk.offline.OfflineManager;
import com.viettel.vtmsdk.maps.OnMapReadyCallback;
import com.viettel.vtmsdk.maps.Style;
import com.mapbox.mapboxsdk.plugins.annotation.Annotation;
import com.mapbox.mapboxsdk.plugins.annotation.Circle;
import com.mapbox.mapboxsdk.plugins.annotation.CircleManager;
import com.mapbox.mapboxsdk.plugins.annotation.Fill;
import com.mapbox.mapboxsdk.plugins.annotation.FillManager;
import com.mapbox.mapboxsdk.plugins.annotation.OnAnnotationClickListener;
import com.mapbox.mapboxsdk.plugins.annotation.Symbol;
import com.mapbox.mapboxsdk.plugins.annotation.SymbolManager;
import com.mapbox.mapboxsdk.plugins.annotation.Line;
import com.mapbox.mapboxsdk.plugins.annotation.LineManager;
import com.mapbox.geojson.Feature;
import com.mapbox.mapboxsdk.plugins.annotation.SymbolOptions;
import com.viettel.vtmsdk.style.expressions.Expression;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.platform.PlatformView;
import retrofit2.Call;
import retrofit2.Response;

import java.io.IOException;
import java.io.InputStream;
import java.net.MalformedURLException;
import java.net.URL;
import java.util.*;
import java.util.concurrent.atomic.AtomicInteger;

import com.mapbox.services.android.navigation.ui.v5.map.NavigationMapboxMap;

import static com.mapbox.core.constants.Constants.PRECISION_6;
import static com.mapbox.mapboxgl.MapboxMapsPlugin.CREATED;
import static com.mapbox.mapboxgl.MapboxMapsPlugin.DESTROYED;
import static com.mapbox.mapboxgl.MapboxMapsPlugin.PAUSED;
import static com.mapbox.mapboxgl.MapboxMapsPlugin.RESUMED;
import static com.mapbox.mapboxgl.MapboxMapsPlugin.STARTED;
import static com.mapbox.mapboxgl.MapboxMapsPlugin.STOPPED;
import static com.viettel.vtmsdk.style.layers.PropertyFactory.visibility;

import com.viettel.vtmsdk.style.layers.FillLayer;
import com.viettel.vtmsdk.style.layers.Layer;
import com.viettel.vtmsdk.style.layers.Property;
import com.viettel.vtmsdk.style.layers.PropertyFactory;
import com.viettel.vtmsdk.style.layers.RasterLayer;
import com.viettel.vtmsdk.style.layers.SymbolLayer;
import com.viettel.vtmsdk.style.sources.GeoJsonSource;
import com.viettel.vtmsdk.style.sources.ImageSource;
import com.viettel.maps.v3.control.maptype.*;
import com.viettel.vtmsdk.style.sources.Source;

/**
 * Controller of a single MapboxMaps MapView instance.
 */
final class MapboxMapController
        implements Application.ActivityLifecycleCallbacks,
        VTMap.OnCameraIdleListener,
        VTMap.OnCameraMoveListener,
        VTMap.OnCameraMoveStartedListener,
        OnAnnotationClickListener,
        VTMap.OnMapClickListener,
        VTMap.OnMapLongClickListener,
        MapboxMapOptionsSink,
        MethodChannel.MethodCallHandler,
        OnMapReadyCallback,
        OnCameraTrackingChangedListener,
        OnSymbolTappedListener,
        OnLineTappedListener,
        OnCircleTappedListener,
        OnFillTappedListener,
        PlatformView {
    private static final String TAG = "MapboxMapController";
    private final int id;
    private final AtomicInteger activityState;
    private final MethodChannel methodChannel;
    private final PluginRegistry.Registrar registrar;
    private final MapView mapView;
    private VTMap mapboxMap;
    private final Map<String, SymbolController> symbols;
    private final Map<String, LineController> lines;
    private final Map<String, CircleController> circles;
    private final Map<String, FillController> fills;
    private SymbolManager symbolManager;
    private LineManager lineManager;
    private CircleManager circleManager;
    private FillManager fillManager;
    private boolean trackCameraPosition = false;
    private boolean myLocationEnabled = true;
    private boolean myGPSControlEnabled = false;
    private boolean myMapTypeControlEnabled = false;
    private int myLocationTrackingMode = 0;
    private int myLocationRenderMode = 0;
    private boolean disposed = false;
    private final float density;
    private MethodChannel.Result mapReadyResult;
    private final int registrarActivityHashCode;
    private final Context context;
    private final String styleStringInitial;
    private LocationComponent locationComponent = null;
    private LocationEngine locationEngine = null;
    private LocationEngineCallback<LocationEngineResult> locationEngineCallback = null;
    private Style style;
    private NavigationMapboxMap navigationMapboxMap;
    private String navigationPadding = "50,100,50,100";//left,top,right,bottom
    private List<DirectionsRoute> directionsRoutes;
    private boolean logoEnable;

    MapboxMapController(
            int id,
            Context context,
            AtomicInteger activityState,
            PluginRegistry.Registrar registrar,
            VTMapOptions options,
            String accessToken,
            String styleStringInitial) {
        MapVT.getInstance(context, accessToken != null ? accessToken : getAccessToken(context));
        this.id = id;
        this.context = context;
        this.activityState = activityState;
        this.registrar = registrar;
        this.styleStringInitial = styleStringInitial += "?access_token=" + accessToken;
        this.mapView = new MapView(context, options);
        this.symbols = new HashMap<>();
        this.lines = new HashMap<>();
        this.circles = new HashMap<>();
        this.fills = new HashMap<>();
        this.density = context.getResources().getDisplayMetrics().density;
        methodChannel =
                new MethodChannel(registrar.messenger(), "plugins.flutter.io/mapbox_maps_" + id);
        methodChannel.setMethodCallHandler(this);
        this.registrarActivityHashCode = registrar.activity().hashCode();
        if (accessToken == null || accessToken.isEmpty()) {
            throw new NullPointerException("AccessToken is missing");
        }
    }

    private static String getAccessToken(@NonNull Context context) {
        try {
            ApplicationInfo ai = context.getPackageManager().getApplicationInfo(context.getPackageName(), PackageManager.GET_META_DATA);
            Bundle bundle = ai.metaData;
            String token = bundle.getString("VTMapAccessToken");
            if (token == null || token.isEmpty()) {
                throw new NullPointerException();
            }
            return token;
        } catch (Exception e) {
            Log.e(TAG, "Failed to find an Access Token in the Application meta-data. Maps may not load correctly. " +
                    "Please refer to the installation guide at https://github.com/tobrun/flutter-mapbox-gl#mapbox-access-token " +
                    "for troubleshooting advice." + e.getMessage());
        }
        return null;
    }

    @Override
    public View getView() {
        return mapView;
    }

    void init() {
        switch (activityState.get()) {
            case STOPPED:
                mapView.onCreate(null);
                mapView.onStart();
                mapView.onResume();
                mapView.onPause();
                mapView.onStop();
                break;
            case PAUSED:
                mapView.onCreate(null);
                mapView.onStart();
                mapView.onResume();
                mapView.onPause();
                break;
            case RESUMED:
                mapView.onCreate(null);
                mapView.onStart();
                mapView.onResume();
                break;
            case STARTED:
                mapView.onCreate(null);
                mapView.onStart();
                break;
            case CREATED:
                mapView.onCreate(null);
                break;
            case DESTROYED:
                mapboxMap.removeOnCameraIdleListener(this);
                mapboxMap.removeOnCameraMoveStartedListener(this);
                mapboxMap.removeOnCameraMoveListener(this);
                mapView.onDestroy();
                break;
            default:
                throw new IllegalArgumentException(
                        "Cannot interpret " + activityState.get() + " as an activity state");
        }
        registrar.activity().getApplication().registerActivityLifecycleCallbacks(this);
        mapView.getMapAsync(this);
    }

    private void moveCamera(CameraUpdate cameraUpdate) {
        mapboxMap.moveCamera(cameraUpdate);
    }

    private void animateCamera(CameraUpdate cameraUpdate) {
        mapboxMap.animateCamera(cameraUpdate);
    }

    private CameraPosition getCameraPosition() {
        return trackCameraPosition ? mapboxMap.getCameraPosition() : null;
    }

    private SymbolController symbol(String symbolId) {
        final SymbolController symbol = symbols.get(symbolId);
        if (symbol == null) {
            throw new IllegalArgumentException("Unknown symbol: " + symbolId);
        }
        return symbol;
    }

    private LineBuilder newLineBuilder() {
        return new LineBuilder(lineManager);
    }

    private void removeLine(String lineId) {
        final LineController lineController = lines.remove(lineId);
        if (lineController != null) {
            lineController.remove(lineManager);
        }
    }

    private LineController line(String lineId) {
        final LineController line = lines.get(lineId);
        if (line == null) {
            throw new IllegalArgumentException("Unknown line: " + lineId);
        }
        return line;
    }

    private CircleBuilder newCircleBuilder() {
        return new CircleBuilder(circleManager);
    }

    private void removeCircle(String circleId) {
        final CircleController circleController = circles.remove(circleId);
        if (circleController != null) {
            circleController.remove(circleManager);
        }
    }

    private CircleController circle(String circleId) {
        final CircleController circle = circles.get(circleId);
        if (circle == null) {
            throw new IllegalArgumentException("Unknown circle: " + circleId);
        }
        return circle;
    }

    private FillBuilder newFillBuilder() {
        return new FillBuilder(fillManager);
    }

    private void removeFill(String fillId) {
        final FillController fillController = fills.remove(fillId);
        if (fillController != null) {
            fillController.remove(fillManager);
        }
    }

    private FillController fill(String fillId) {
        final FillController fill = fills.get(fillId);
        if (fill == null) {
            throw new IllegalArgumentException("Unknown fill: " + fillId);
        }
        return fill;
    }

    @Override
    public void onMapReady(VTMap mapboxMap) {
        this.mapboxMap = mapboxMap;
        if (mapReadyResult != null) {
            mapReadyResult.success(null);
            mapReadyResult = null;
        }
        mapboxMap.addOnCameraMoveStartedListener(this);
        mapboxMap.addOnCameraMoveListener(this);
        mapboxMap.addOnCameraIdleListener(this);

        mapView.addOnStyleImageMissingListener((id) -> {
            DisplayMetrics displayMetrics = context.getResources().getDisplayMetrics();
            final Bitmap bitmap = getScaledImage(id, displayMetrics.density);
            if (bitmap != null) {
                mapboxMap.getStyle().addImage(id, bitmap);
            }
        });

        setStyleString(styleStringInitial);
        // updateMyLocationEnabled();

    }

    @Override
    public void setStyleString(String styleString) {
        //check if json, url or plain string:
        if (styleString == null || styleString.isEmpty()) {
            Log.e(TAG, "setStyleString - string empty or null");
        } else if (styleString.startsWith("{") || styleString.startsWith("[")) {
            mapboxMap.setStyle(new Style.Builder().fromJson(styleString), onStyleLoadedCallback);
        } else if (
                !styleString.startsWith("http://") &&
                        !styleString.startsWith("https://") &&
                        !styleString.startsWith("mapbox://")) {
            // We are assuming that the style will be loaded from an asset here.
            AssetManager assetManager = registrar.context().getAssets();
            String key = registrar.lookupKeyForAsset(styleString);
            mapboxMap.setStyle(new Style.Builder().fromUri("asset://" + key), onStyleLoadedCallback);
        } else {
            mapboxMap.setStyle(new Style.Builder().fromUrl(styleString), onStyleLoadedCallback);
        }
    }

    Style.OnStyleLoaded onStyleLoadedCallback = new Style.OnStyleLoaded() {
        @Override
        public void onStyleLoaded(@NonNull Style style) {
            if (navigationMapboxMap == null) {
                navigationMapboxMap = new NavigationMapboxMap(mapView, mapboxMap);
                navigationMapboxMap.updateLocationLayerRenderMode(RenderMode.NORMAL);
                navigationMapboxMap.setOnRouteSelectionChangeListener(new OnRouteSelectionChangeListener() {
                    @Override
                    public void onNewPrimaryRouteSelected(DirectionsRoute directionsRoute) {
                        String routeIndex = directionsRoute.routeIndex();
                        final Map<String, Object> arguments = new HashMap<>(1);
                        arguments.put("routeIndex", Integer.valueOf(routeIndex));
                        methodChannel.invokeMethod("map#onRouteSelected", arguments);
                    }
                });
            }

            MapboxMapController.this.style = style;
            enableLineManager(style);
            enableSymbolManager(style);
            enableCircleManager(style);
            enableFillManager(style);
            setGPSControlEnable(myGPSControlEnabled);
            setMapTypeControlEnable(myMapTypeControlEnabled);
            setLogoEnable(logoEnable);
            if (myLocationEnabled) {
                enableLocationComponent(style);
            }
            // needs to be placed after SymbolManager#addClickListener,
            // is fixed with 0.6.0 of annotations plugin
            mapboxMap.addOnMapClickListener(MapboxMapController.this);
            mapboxMap.addOnMapLongClickListener(MapboxMapController.this);

            methodChannel.invokeMethod("map#onStyleLoaded", null);


        }
    };

    @SuppressWarnings({"MissingPermission"})
    private void enableLocationComponent(@NonNull Style style) {
        if (hasLocationPermission()) {
            locationEngine = LocationEngineProvider.getBestLocationEngine(context);
            LocationComponentOptions locationComponentOptions = LocationComponentOptions.builder(context)
                    .trackingGesturesManagement(true)
                    .build();
            locationComponent = mapboxMap.getLocationComponent();
            locationComponent.activateLocationComponent(context, style, locationComponentOptions);
            locationComponent.setLocationComponentEnabled(true);
            // locationComponent.setRenderMode(RenderMode.COMPASS); // remove or keep default?
            locationComponent.setLocationEngine(locationEngine);
            locationComponent.setMaxAnimationFps(30);
            updateMyLocationTrackingMode();
            setMyLocationTrackingMode(this.myLocationTrackingMode);
            updateMyLocationRenderMode();
            setMyLocationRenderMode(this.myLocationRenderMode);
            locationComponent.addOnCameraTrackingChangedListener(this);
        } else {
            Log.e(TAG, "missing location permissions");
        }
    }

    private void onUserLocationUpdate(Location location) {
        if (location == null) {
            return;
        }

        final Map<String, Object> userLocation = new HashMap<>(6);
        userLocation.put("position", new double[]{location.getLatitude(), location.getLongitude()});
        userLocation.put("altitude", location.getAltitude());
        userLocation.put("bearing", location.getBearing());
        userLocation.put("horizontalAccuracy", location.getAccuracy());
        userLocation.put("verticalAccuracy", (android.os.Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) ? location.getVerticalAccuracyMeters() : null);
        userLocation.put("timestamp", location.getTime());

        final Map<String, Object> arguments = new HashMap<>(1);
        arguments.put("userLocation", userLocation);
        methodChannel.invokeMethod("map#onUserLocationUpdated", arguments);
    }

    private void enableSymbolManager(@NonNull Style style) {
        if (symbolManager == null) {
            symbolManager = new SymbolManager(mapView, mapboxMap, style);
            symbolManager.setIconAllowOverlap(false);
            symbolManager.setIconIgnorePlacement(false);
            symbolManager.setTextAllowOverlap(false);
            symbolManager.setTextIgnorePlacement(false);
            symbolManager.addClickListener(MapboxMapController.this::onAnnotationClick);
        }
    }


    private void enableLineManager(@NonNull Style style) {
        if (lineManager == null) {
            lineManager = new LineManager(mapView, mapboxMap, style);
            lineManager.addClickListener(MapboxMapController.this::onAnnotationClick);
        }
    }

    private void enableCircleManager(@NonNull Style style) {
        if (circleManager == null) {
            circleManager = new CircleManager(mapView, mapboxMap, style);
            circleManager.addClickListener(MapboxMapController.this::onAnnotationClick);
        }
    }

    private void enableFillManager(@NonNull Style style) {
        if (fillManager == null) {
            fillManager = new FillManager(mapView, mapboxMap, style);
            fillManager.addClickListener(MapboxMapController.this::onAnnotationClick);
        }
    }

    @Override
    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
        switch (call.method) {
            case "map#waitForMap":
                if (mapboxMap != null) {
                    result.success(null);
                    return;
                }
                mapReadyResult = result;
                break;
            case "map#update": {
                Convert.interpretMapboxMapOptions(call.argument("options"), this);
                result.success(Convert.toJson(getCameraPosition()));
                break;
            }
            case "map#updateMyLocationTrackingMode": {
                int myLocationTrackingMode = call.argument("mode");
                setMyLocationTrackingMode(myLocationTrackingMode);
                result.success(null);
                break;
            }
            case "map#matchMapLanguageWithDeviceDefault": {
                try {
                    //localizationPlugin.matchMapLanguageWithDeviceDefault();
                    result.success(null);
                } catch (RuntimeException exception) {
                    Log.d(TAG, exception.toString());
                    result.error("MAPBOX LOCALIZATION PLUGIN ERROR", exception.toString(), null);
                }
                break;
            }
            case "map#setMapLanguage": {
                final String language = call.argument("language");
                try {
                    // localizationPlugin.setMapLanguage(language);
                    result.success(null);
                } catch (RuntimeException exception) {
                    Log.d(TAG, exception.toString());
                    result.error("MAPBOX LOCALIZATION PLUGIN ERROR", exception.toString(), null);
                }
                break;
            }
            case "map#getVisibleRegion": {
                Map<String, Object> reply = new HashMap<>();
                VisibleRegion visibleRegion = mapboxMap.getProjection().getVisibleRegion();
                reply.put("sw", Arrays.asList(visibleRegion.nearLeft.getLatitude(), visibleRegion.nearLeft.getLongitude()));
                reply.put("ne", Arrays.asList(visibleRegion.farRight.getLatitude(), visibleRegion.farRight.getLongitude()));
                result.success(reply);
                break;
            }
            case "map#toScreenLocation": {
                Map<String, Object> reply = new HashMap<>();
                PointF pointf = mapboxMap.getProjection().toScreenLocation(new LatLng(call.argument("latitude"), call.argument("longitude")));
                reply.put("x", pointf.x);
                reply.put("y", pointf.y);
                result.success(reply);
                break;
            }
            case "map#toLatLng": {
                Map<String, Object> reply = new HashMap<>();
                LatLng latlng = mapboxMap.getProjection().fromScreenLocation(new PointF(((Double) call.argument("x")).floatValue(), ((Double) call.argument("y")).floatValue()));
                reply.put("latitude", latlng.getLatitude());
                reply.put("longitude", latlng.getLongitude());
                result.success(reply);
                break;
            }
            case "map#getMetersPerPixelAtLatitude": {
                Map<String, Object> reply = new HashMap<>();
                Double retVal = mapboxMap.getProjection().getMetersPerPixelAtLatitude((Double) call.argument("latitude"));
                reply.put("metersperpixel", retVal);
                result.success(reply);
                break;
            }

            case "map#setStyle": {
                String styleString = (String) call.argument("styleString");
                setStyleString(styleString);
                result.success(null);
                break;
            }

            case "map#showOrHideLayer": {
                String layerId = (String) call.argument("layerId");
                Boolean isShow = call.argument("isShow");
                mapboxMap.getStyle(new Style.OnStyleLoaded() {
                    @Override
                    public void onStyleLoaded(@NonNull Style style) {
                        Layer layer = style.getLayer(layerId);
                        if (layer != null && isShow != null) {
                            layer.setProperties(isShow ? visibility(Property.VISIBLE) : visibility(Property.NONE));
                        }
                    }
                });
                result.success(null);
                break;
            }

            case "camera#move": {
                final CameraUpdate cameraUpdate = Convert.toCameraUpdate(call.argument("cameraUpdate"), mapboxMap, density);
                if (cameraUpdate != null) {
                    // camera transformation not handled yet
                    mapboxMap.moveCamera(cameraUpdate, new OnCameraMoveFinishedListener() {
                        @Override
                        public void onFinish() {
                            super.onFinish();
                            result.success(true);
                        }

                        @Override
                        public void onCancel() {
                            super.onCancel();
                            result.success(false);
                        }
                    });

                    // moveCamera(cameraUpdate);
                } else {
                    result.success(false);
                }
                break;
            }
            case "camera#animate": {
                final CameraUpdate cameraUpdate = Convert.toCameraUpdate(call.argument("cameraUpdate"), mapboxMap, density);
                final Integer duration = call.argument("duration");

                final OnCameraMoveFinishedListener onCameraMoveFinishedListener = new OnCameraMoveFinishedListener() {
                    @Override
                    public void onFinish() {
                        super.onFinish();
                        result.success(true);
                    }

                    @Override
                    public void onCancel() {
                        super.onCancel();
                        result.success(false);
                    }
                };
                if (cameraUpdate != null && duration != null) {
                    // camera transformation not handled yet
                    mapboxMap.animateCamera(cameraUpdate, duration, onCameraMoveFinishedListener);
                } else if (cameraUpdate != null) {
                    // camera transformation not handled yet
                    mapboxMap.animateCamera(cameraUpdate, onCameraMoveFinishedListener);
                } else {
                    result.success(false);
                }
                break;
            }
            case "map#queryRenderedFeatures": {
                Map<String, Object> reply = new HashMap<>();
                List<Feature> features;

                String[] layerIds = ((List<String>) call.argument("layerIds")).toArray(new String[0]);

                List<Object> filter = call.argument("filter");
                JsonElement jsonElement = filter == null ? null : new Gson().toJsonTree(filter);
                JsonArray jsonArray = null;
                if (jsonElement != null && jsonElement.isJsonArray()) {
                    jsonArray = jsonElement.getAsJsonArray();
                }
                Expression filterExpression = jsonArray == null ? null : Expression.Converter.convert(jsonArray);
                if (call.hasArgument("x")) {
                    Double x = call.argument("x");
                    Double y = call.argument("y");
                    PointF pixel = new PointF(x.floatValue(), y.floatValue());
                    features = mapboxMap.queryRenderedFeatures(pixel, filterExpression, layerIds);
                } else {
                    Double left = call.argument("left");
                    Double top = call.argument("top");
                    Double right = call.argument("right");
                    Double bottom = call.argument("bottom");
                    RectF rectF = new RectF(left.floatValue(), top.floatValue(), right.floatValue(), bottom.floatValue());
                    features = mapboxMap.queryRenderedFeatures(rectF, filterExpression, layerIds);
                }
                List<String> featuresJson = new ArrayList<>();
                for (Feature feature : features) {
                    featuresJson.add(feature.toJson());
                }
                reply.put("features", featuresJson);
                result.success(reply);
                break;
            }
            case "map#setTelemetryEnabled": {
                final boolean enabled = call.argument("enabled");
                MapVT.getTelemetry().setUserTelemetryRequestState(false);
                result.success(null);
                break;
            }
            case "map#getTelemetryEnabled": {
                final TelemetryEnabler.State telemetryState = TelemetryEnabler.retrieveTelemetryStateFromPreferences();
                result.success(telemetryState == TelemetryEnabler.State.ENABLED);
                break;
            }
            case "map#invalidateAmbientCache": {
                OfflineManager fileSource = OfflineManager.getInstance(context);

                fileSource.invalidateAmbientCache(new OfflineManager.FileSourceCallback() {
                    @Override
                    public void onSuccess() {
                        result.success(null);
                    }

                    @Override
                    public void onError(@NonNull String message) {
                        result.error("MAPBOX CACHE ERROR", message, null);
                    }
                });
                break;
            }
            case "symbols#addAll": {
                List<String> newSymbolIds = new ArrayList<String>();
                final List<Object> options = call.argument("options");
                List<SymbolOptions> symbolOptionsList = new ArrayList<SymbolOptions>();
                if (options != null) {
                    SymbolBuilder symbolBuilder;
                    for (Object o : options) {
                        symbolBuilder = new SymbolBuilder();
                        Convert.interpretSymbolOptions(o, symbolBuilder);
                        SymbolOptions option = symbolBuilder.getSymbolOptions();
                        symbolOptionsList.add(option);
                    }
                    if (!symbolOptionsList.isEmpty()) {
                        List<Symbol> newSymbols = symbolManager.create(symbolOptionsList);
                        String symbolId;
                        for (Symbol symbol : newSymbols) {
                            symbolId = String.valueOf(symbol.getId());
                            newSymbolIds.add(symbolId);
                            symbols.put(symbolId, new SymbolController(symbol, true, this));
                        }
                    }
                }
                result.success(newSymbolIds);
                break;
            }
            case "symbols#removeAll": {
                final ArrayList<String> symbolIds = call.argument("symbols");
                SymbolController symbolController;

                List<Symbol> symbolList = new ArrayList<Symbol>();
                for (String symbolId : symbolIds) {
                    symbolController = symbols.remove(symbolId);
                    if (symbolController != null) {
                        symbolList.add(symbolController.getSymbol());
                    }
                }
                if (!symbolList.isEmpty()) {
                    symbolManager.delete(symbolList);
                }
                result.success(null);
                break;
            }
            case "symbol#update": {
                final String symbolId = call.argument("symbol");
                final SymbolController symbol = symbol(symbolId);
                Convert.interpretSymbolOptions(call.argument("options"), symbol);
                symbol.update(symbolManager);
                result.success(null);
                break;
            }
            case "symbol#getGeometry": {
                final String symbolId = call.argument("symbol");
                final SymbolController symbol = symbol(symbolId);
                final LatLng symbolLatLng = symbol.getGeometry();
                Map<String, Double> hashMapLatLng = new HashMap<>();
                hashMapLatLng.put("latitude", symbolLatLng.getLatitude());
                hashMapLatLng.put("longitude", symbolLatLng.getLongitude());
                result.success(hashMapLatLng);
            }
            case "symbolManager#iconAllowOverlap": {
                final Boolean value = call.argument("iconAllowOverlap");
                symbolManager.setIconAllowOverlap(value);
                result.success(null);
                break;
            }
            case "symbolManager#iconIgnorePlacement": {
                final Boolean value = call.argument("iconIgnorePlacement");
                symbolManager.setIconIgnorePlacement(value);
                result.success(null);
                break;
            }
            case "symbolManager#textAllowOverlap": {
                final Boolean value = call.argument("textAllowOverlap");
                symbolManager.setTextAllowOverlap(value);
                result.success(null);
                break;
            }
            case "symbolManager#textIgnorePlacement": {
                final Boolean iconAllowOverlap = call.argument("textIgnorePlacement");
                symbolManager.setTextIgnorePlacement(iconAllowOverlap);
                result.success(null);
                break;
            }
            case "line#add": {
                final LineBuilder lineBuilder = newLineBuilder();
                Convert.interpretLineOptions(call.argument("options"), lineBuilder);
                final Line line = lineBuilder.build();
                final String lineId = String.valueOf(line.getId());
                lines.put(lineId, new LineController(line, true, this));
                result.success(lineId);
                break;
            }
            case "line#remove": {
                final String lineId = call.argument("line");
                removeLine(lineId);
                result.success(null);
                break;
            }
            case "line#update": {
                final String lineId = call.argument("line");
                final LineController line = line(lineId);
                Convert.interpretLineOptions(call.argument("options"), line);
                line.update(lineManager);
                result.success(null);
                break;
            }
            case "line#getGeometry": {
                final String lineId = call.argument("line");
                final LineController line = line(lineId);
                final List<LatLng> lineLatLngs = line.getGeometry();
                final List<Object> resultList = new ArrayList<>();
                for (LatLng latLng : lineLatLngs) {
                    Map<String, Double> hashMapLatLng = new HashMap<>();
                    hashMapLatLng.put("latitude", latLng.getLatitude());
                    hashMapLatLng.put("longitude", latLng.getLongitude());
                    resultList.add(hashMapLatLng);
                }
                result.success(resultList);
                break;
            }
            case "circle#add": {
                final CircleBuilder circleBuilder = newCircleBuilder();
                Convert.interpretCircleOptions(call.argument("options"), circleBuilder);
                final Circle circle = circleBuilder.build();
                final String circleId = String.valueOf(circle.getId());
                circles.put(circleId, new CircleController(circle, true, this));
                result.success(circleId);
                break;
            }
            case "circle#remove": {
                final String circleId = call.argument("circle");
                removeCircle(circleId);
                result.success(null);
                break;
            }
            case "circle#update": {
                Log.e(TAG, "update circle");
                final String circleId = call.argument("circle");
                final CircleController circle = circle(circleId);
                Convert.interpretCircleOptions(call.argument("options"), circle);
                circle.update(circleManager);
                result.success(null);
                break;
            }
            case "circle#getGeometry": {
                final String circleId = call.argument("circle");
                final CircleController circle = circle(circleId);
                final LatLng circleLatLng = circle.getGeometry();
                Map<String, Double> hashMapLatLng = new HashMap<>();
                hashMapLatLng.put("latitude", circleLatLng.getLatitude());
                hashMapLatLng.put("longitude", circleLatLng.getLongitude());
                result.success(hashMapLatLng);
                break;
            }
            case "fill#add": {
                final FillBuilder fillBuilder = newFillBuilder();
                Convert.interpretFillOptions(call.argument("options"), fillBuilder);
                final Fill fill = fillBuilder.build();
                final String fillId = String.valueOf(fill.getId());
                fills.put(fillId, new FillController(fill, true, this));
                result.success(fillId);
                break;
            }
            case "fill#remove": {
                final String fillId = call.argument("fill");
                removeFill(fillId);
                result.success(null);
                break;
            }
            case "fill#update": {
                Log.e(TAG, "update fill");
                final String fillId = call.argument("fill");
                final FillController fill = fill(fillId);
                Convert.interpretFillOptions(call.argument("options"), fill);
                fill.update(fillManager);
                result.success(null);
                break;
            }
            case "locationComponent#getLastLocation": {
                Log.e(TAG, "location component: getLastLocation");
                if (this.myLocationEnabled && locationComponent != null && locationEngine != null) {
                    Map<String, Object> reply = new HashMap<>();
                    locationEngine.getLastLocation(new LocationEngineCallback<LocationEngineResult>() {
                        @Override
                        public void onSuccess(LocationEngineResult locationEngineResult) {
                            Location lastLocation = locationEngineResult.getLastLocation();
                            if (lastLocation != null) {
                                reply.put("latitude", lastLocation.getLatitude());
                                reply.put("longitude", lastLocation.getLongitude());
                                reply.put("altitude", lastLocation.getAltitude());
                                result.success(reply);
                            } else {
                                result.error("", "", null); // ???
                            }
                        }

                        @Override
                        public void onFailure(@NonNull Exception exception) {
                            result.error("", "", null); // ???
                        }
                    });
                }
                break;
            }

            case "style#addSymbolLayer": {
                addSymbolLayer(call);
                result.success(null);
                break;
            }

            case "style#addImage": {
                if (style == null) {
                    result.error("STYLE IS NULL", "The style is null. Has onStyleLoaded() already been invoked?", null);
                }
                style.addImage(call.argument("name"), BitmapFactory.decodeByteArray(call.argument("bytes"), 0, call.argument("length")), call.argument("sdf"));
                result.success(null);
                break;
            }
            case "style#addImageSource": {
                if (style == null) {
                    result.error("STYLE IS NULL", "The style is null. Has onStyleLoaded() already been invoked?", null);
                }
                List<LatLng> coordinates = Convert.toLatLngList(call.argument("coordinates"));
                style.addSource(new ImageSource(call.argument("name"), new LatLngQuad(coordinates.get(0), coordinates.get(1), coordinates.get(2), coordinates.get(3)), BitmapFactory.decodeByteArray(call.argument("bytes"), 0, call.argument("length"))));
                result.success(null);
                break;
            }
            case "style#removeImageSource": {
                if (style == null) {
                    result.error("STYLE IS NULL", "The style is null. Has onStyleLoaded() already been invoked?", null);
                }
                style.removeSource((String) call.argument("name"));
                result.success(null);
                break;
            }
            case "style#addLayer": {
                if (style == null) {
                    result.error("STYLE IS NULL", "The style is null. Has onStyleLoaded() already been invoked?", null);
                }
                style.addLayer(new RasterLayer(call.argument("name"), call.argument("sourceId")));
                result.success(null);
                break;
            }
            case "style#removeLayer": {
                if (style == null) {
                    result.error("STYLE IS NULL", "The style is null. Has onStyleLoaded() already been invoked?", null);
                }
                style.removeLayer((String) call.argument("name"));
                result.success(null);
                break;
            }
            case "map#buildRoute": {
                buildRoute(call, result);
                result.success(null);
                break;
            }
            case "map#selectedRoute": {
                int index = call.argument("routeSelectedIndex");

                if (call.argument("padding") != null) {
                    String padding = (String) call.argument("padding");
                    String[] paddings = padding.split(",");
                    if (paddings.length == 4) {
                        this.navigationPadding = call.argument("padding");
                    }
                }

                if (directionsRoutes != null && directionsRoutes.size() > index) {
                    navigationMapboxMap.redrawPrimeRoute(index);
                    boundCameraToRoute(directionsRoutes.get(index));
                }
                result.success(null);
                break;
            }
            case "map#startNavigation": {
                startNavigation(call, result);
                result.success(null);
                break;
            }
            case "map#clearRoute": {
                clearRoute();
                result.success(null);
                break;
            }

            case "map#showRoutes": {

                result.success(null);
                break;
            }


            default:
                result.notImplemented();
        }
    }

    private void addSymbolLayer(MethodCall methodCall) {
        try {
            String layerId = methodCall.argument("layerId");
            String sourceId = layerId;
            String sourceUrl = methodCall.argument("sourceUrl");
            String layerAbove = methodCall.argument("layerAbove");
            String layerBelow = methodCall.argument("layerBelow");
            String layerType = methodCall.argument("layerType");
            final Object options = methodCall.argument("options");

            Log.d("=====sourceUrl", sourceUrl);
            URL url = new URL(sourceUrl);
            mapboxMap.getStyle(new Style.OnStyleLoaded() {
                @Override
                public void onStyleLoaded(@NonNull Style style) {
                    Layer layer = style.getLayer(layerId);
                    Source source = style.getSource(sourceId);
                    Log.d("====", layerId);
                    if (source != null) {
                        Log.d("====removeSource", layerId);
                        style.removeSource(source);
                    }
                    source = new GeoJsonSource(sourceId, url);
                    style.addSource(source);

                    if (layer != null) {
                        style.removeLayer(layer);
                    }

                    if (("symbol").equals(layerType)) {
                        layer = new SymbolLayer(layerId, sourceId);
                    } else {//polygon
                        layer = new FillLayer(layerId, sourceId);
                    }

                    setLayerProperties(options, layer,layerType);

                    if (layerAbove != null) {
                        style.addLayerAbove(layer, layerAbove);
                    } else if (layerBelow != null) {
                        style.addLayerBelow(layer, layerBelow);
                    } else {
                        style.addLayer(layer);
                    }
                }
            });
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    void setLayerProperties(Object options, Layer layer,String layerType) {
        if (options != null) {
            final Map<?, ?> data = Convert.toMap(options);
            final Object iconSize = data.get("iconSize");
            if (("symbol").equals(layerType)) {
                if (iconSize != null) {
                    layer.setProperties(PropertyFactory.iconSize(Convert.toFloat(iconSize)));
                }

                String iconImage = (String) data.get("iconImage");
                if (iconImage != null) {
                    layer.setProperties(PropertyFactory.iconImage(iconImage));
                }

                Boolean symbolIconAllowOverlap = (Boolean) data.get("symbolIconAllowOverlap");
                if (symbolIconAllowOverlap != null) {
                    layer.setProperties(PropertyFactory.iconAllowOverlap(symbolIconAllowOverlap));
                }
            }else{
                String  fillColor =(String) data.get("fillColor");
                if (fillColor != null) {
                    layer.setProperties(PropertyFactory.fillColor(fillColor));
                }

                Object  fillOpacity = data.get("fillOpacity");
                if (fillOpacity != null) {
                    layer.setProperties(PropertyFactory.fillOpacity(Convert.toFloat(fillOpacity)));
                }

                String fillOutLineColor = (String) data.get("fillOutLineColor");
                if (fillOutLineColor != null) {
                    Log.d("fillOutLineColor",fillOutLineColor);
                    layer.setProperties(PropertyFactory.fillOutlineColor(fillOutLineColor));
                }

            }


        }
    }

    private void buildRoute(MethodCall methodCall, MethodChannel.Result result) {

        if (methodCall.argument("wayPoints") != null) {
            List<Point> wayPoints = new ArrayList<Point>();
            HashMap<String, Map<String, Object>> argumentWayPoints = (HashMap<String, Map<String, Object>>) methodCall.argument("wayPoints");
            HashMap<Integer, Point> mapPoints = new HashMap<>();

            for (Map.Entry<String, Map<String, Object>> item : argumentWayPoints.entrySet()) {
                int order = (int) item.getValue().get("Order");
                Double latitude = (Double) item.getValue().get("Latitude");
                Double longitude = (Double) item.getValue().get("Longitude");
                mapPoints.put(order, Point.fromLngLat(longitude, latitude));
            }

            for (int i = 0; i < mapPoints.size(); i++) {
                wayPoints.add(mapPoints.get(i));
            }

            if (methodCall.argument("padding") != null) {
                String padding = (String) methodCall.argument("padding");
                String[] paddings = padding.split(",");
                if (paddings.length == 4) {
                    this.navigationPadding = methodCall.argument("padding");
                }
            }

            getRoute(wayPoints, methodCall);
            result.success(true);
        }
    }

    private void startNavigation(MethodCall methodCall, MethodChannel.Result result) {
        if (methodCall.argument("wayPoints") != null) {
            List<Point> wayPoints = new ArrayList<Point>();
            HashMap<Integer, Point> mapPoints = new HashMap<>();

            HashMap<String, Map<String, Object>> argumentWayPoints = (HashMap<String, Map<String, Object>>) methodCall.argument("wayPoints");
            for (Map.Entry<String, Map<String, Object>> item : argumentWayPoints.entrySet()) {
                int order = (int) item.getValue().get("Order");
                Double latitude = (Double) item.getValue().get("Latitude");
                Double longitude = (Double) item.getValue().get("Longitude");
                mapPoints.put(order, Point.fromLngLat(longitude, latitude));
            }

            for (int i = 0; i < mapPoints.size(); i++) {
                wayPoints.add(mapPoints.get(i));
            }

            if (wayPoints.size() < 2) {
                return;
            }

            Point originPoint = wayPoints.get(0);
            Point destinationPoint = wayPoints.get(wayPoints.size() - 1);
            String profile = DirectionsCriteria.PROFILE_DRIVING;
            boolean shouldSimulateRoute = (methodCall.argument("simulateRoute") != null && (boolean) methodCall.argument("simulateRoute") == true) ? true : false;
            if (methodCall.argument("mode") != null) {
                profile = methodCall.argument("mode");
                if (profile.equalsIgnoreCase(DirectionsCriteria.PROFILE_DRIVING)) {
                    profile = DirectionsCriteria.PROFILE_DRIVING;
                } else if (profile.equalsIgnoreCase(DirectionsCriteria.PROFILE_CYCLING)) {
                    profile = DirectionsCriteria.PROFILE_CYCLING;
                } else {
                    profile = DirectionsCriteria.PROFILE_DRIVING;
                }
            }

            boolean alternatives = false;
            if (methodCall.argument("alternatives") != null) {
                alternatives = (Boolean) methodCall.argument("alternatives");
            }
            int startIndex = 0;
            if (methodCall.argument("startIndex") != null) {
                startIndex = methodCall.argument("startIndex");
            }
            int finalStartIndex = startIndex;

            NavigationRoute.Builder builder = NavigationRoute.builder(context)
                    .accessToken(MapVT.getAccessToken() != null ? MapVT.getAccessToken() : "")
                    .profile(profile)//driving: cho oto va cycling: cho xe may
                    .alternatives(alternatives)//cho phep hien thi tuyen duong goi y hay khong(trong truong hop tim thay 2 tuyen duong tro len)
                    .packageId(MapVT.getPackageName());

            builder.origin(originPoint);
            builder.destination(destinationPoint);

            NavigationRoute navigationRoute = builder.build();

            navigationRoute.getRoute(new SimplifiedCallback() {
                @Override
                public void onResponse(Call<DirectionsResponse> call, Response<DirectionsResponse> response) {
                    List<DirectionsRoute> routesFetched = response.body().routes();
                    if (routesFetched.size() > 0) {
                        NavigationLauncherOptions.Builder optionsBuilder = NavigationLauncherOptions.builder()
                                .shouldSimulateRoute(shouldSimulateRoute);

                        CameraPosition initialPosition = new CameraPosition.Builder()
                                .target(new LatLng(originPoint.latitude(), originPoint.longitude()))
                                .zoom(10)
                                .build();
                        optionsBuilder.initialMapCameraPosition(initialPosition);
                        optionsBuilder.mapStyle(Style.VTMAP_TRAFFIC_DAY);
                        if (finalStartIndex < routesFetched.size()) {
                            optionsBuilder.directionsRoute(routesFetched.get(finalStartIndex));
                        } else {
                            optionsBuilder.directionsRoute(routesFetched.get(0));
                        }
                        NavigationLauncher.startNavigation(registrar.activity(), optionsBuilder.build());
                    }

                }

                @Override
                public void onFailure(Call<DirectionsResponse> call, Throwable throwable) {
                    super.onFailure(call, throwable);

                }
            });
            result.success(true);
        }
    }

    private void clearRoute() {
        if (navigationMapboxMap != null) {
            navigationMapboxMap.clearMarkers();
            navigationMapboxMap.removeRoute();
        }
    }

    private void getRoute(List<Point> wayPoints, MethodCall methodCall) {
        if (wayPoints.size() < 2) {
            return;
        }

        Point originPoint = wayPoints.get(0);
        Point destinationPoint = wayPoints.get(wayPoints.size() - 1);

        //navigationMapboxMap.updateLocationLayerRenderMode(RenderMode.GPS);
        String profile = DirectionsCriteria.PROFILE_DRIVING;
        if (methodCall.argument("mode") != null) {
            profile = methodCall.argument("mode");
            if (profile.equalsIgnoreCase(DirectionsCriteria.PROFILE_DRIVING)) {
                profile = DirectionsCriteria.PROFILE_DRIVING;
            } else if (profile.equalsIgnoreCase(DirectionsCriteria.PROFILE_CYCLING)) {
                profile = DirectionsCriteria.PROFILE_CYCLING;
            } else {
                profile = DirectionsCriteria.PROFILE_DRIVING;
            }
        }

        boolean alternatives = false;
        if (methodCall.argument("alternatives") != null) {
            alternatives = (Boolean) methodCall.argument("alternatives");
        }

        directionsRoutes = new ArrayList<>();
        NavigationRoute.Builder builder = NavigationRoute.builder(context)
                .accessToken(MapVT.getAccessToken() != null ? MapVT.getAccessToken() : "")
                .profile(profile)//driving: cho oto va cycling: cho xe may
                .alternatives(alternatives)//cho phep hien thi tuyen duong goi y hay khong(trong truong hop tim thay 2 tuyen duong tro len)
                .packageId(MapVT.getPackageName());

        builder.origin(originPoint);
        builder.destination(destinationPoint);

        if (wayPoints.size() > 2) {
            for (int i = 1; i < wayPoints.size() - 1; i++) {
                builder.addWaypoint(wayPoints.get(i));
            }
        }

        NavigationRoute navigationRoute = builder.build();
        navigationRoute.getRoute(new SimplifiedCallback() {
            @Override
            public void onResponse(Call<DirectionsResponse> call, Response<DirectionsResponse> response) {
                List<DirectionsRoute> routesFetched = response.body().routes();
                directionsRoutes.addAll(routesFetched);
                if (routesFetched != null && routesFetched.size() > 0) {
                    navigationMapboxMap.drawRoutes(routesFetched);

                    boundCameraToRoute(routesFetched.get(0));
                }
            }

            @Override
            public void onFailure(Call<DirectionsResponse> call, Throwable throwable) {
                super.onFailure(call, throwable);

            }
        });
    }

    private void boundCameraToRoute(DirectionsRoute route) {
        if (route != null) {
            List<Point> routeCoords = LineString.fromPolyline(route.geometry(),
                    PRECISION_6).coordinates();
            List<LatLng> bboxPoints = new ArrayList<>();
            for (Point point : routeCoords) {
                bboxPoints.add(new LatLng(point.latitude(), point.longitude()));
            }

            if (bboxPoints.size() > 1) {
                try {
                    LatLngBounds bounds = new LatLngBounds.Builder().includes(bboxPoints).build();
                    // left, top, right, bottom
                    int topPadding = 100;//directionFrame.getHeight() * 2;
                    CameraPosition position;
                    if (navigationPadding != null && navigationPadding.split(",").length == 4) {
                        String[] paddings = navigationPadding.split(",");
                        position = mapboxMap.getCameraForLatLngBounds(bounds, new int[]{Integer.valueOf(paddings[0]), Integer.valueOf(paddings[1]), Integer.valueOf(paddings[2]), Integer.valueOf(paddings[3])});
                    } else {
                        position = mapboxMap.getCameraForLatLngBounds(bounds, new int[]{50, topPadding, 50, 100});
                    }

                    CameraUpdate cameraUpdate = CameraUpdateFactory.newCameraPosition(position);
                    //mapboxMap.moveCamera(cameraUpdate);

                    NavigationCameraUpdate navigationCameraUpdate = new NavigationCameraUpdate(cameraUpdate);
                    navigationCameraUpdate.setMode(CameraUpdateMode.OVERRIDE);
                    navigationMapboxMap.retrieveCamera().update(navigationCameraUpdate, 2000);

                    // mapboxMap.moveCamera(cameraUpdate);

                } catch (Exception exception) {
                    exception.printStackTrace();
                }
            }
        }
    }

    @Override
    public void onCameraMoveStarted(int reason) {
        final Map<String, Object> arguments = new HashMap<>(2);
        boolean isGesture = reason == VTMap.OnCameraMoveStartedListener.REASON_API_GESTURE;
        arguments.put("isGesture", isGesture);
        methodChannel.invokeMethod("camera#onMoveStarted", arguments);
    }

    @Override
    public void onCameraMove() {
        if (!trackCameraPosition) {
            return;
        }
        final Map<String, Object> arguments = new HashMap<>(2);
        arguments.put("position", Convert.toJson(mapboxMap.getCameraPosition()));
        methodChannel.invokeMethod("camera#onMove", arguments);
    }

    @Override
    public void onCameraIdle() {
        methodChannel.invokeMethod("camera#onIdle", Collections.singletonMap("map", id));
    }

    @Override
    public void onCameraTrackingChanged(int currentMode) {
        final Map<String, Object> arguments = new HashMap<>(2);
        arguments.put("mode", currentMode);
        methodChannel.invokeMethod("map#onCameraTrackingChanged", arguments);
    }

    @Override
    public void onCameraTrackingDismissed() {
        this.myLocationTrackingMode = 0;
        methodChannel.invokeMethod("map#onCameraTrackingDismissed", new HashMap<>());
    }

    @Override
    public void onAnnotationClick(Annotation annotation) {
        if (annotation instanceof Symbol) {
            final SymbolController symbolController = symbols.get(String.valueOf(annotation.getId()));
            if (symbolController != null) {
                symbolController.onTap();
                // return true;
            }
        }

        if (annotation instanceof Line) {
            final LineController lineController = lines.get(String.valueOf(annotation.getId()));
            if (lineController != null) {
                lineController.onTap();
                // return true;
            }
        }

        if (annotation instanceof Circle) {
            final CircleController circleController = circles.get(String.valueOf(annotation.getId()));
            if (circleController != null) {
                circleController.onTap();
                // return true;
            }
        }
        if (annotation instanceof Fill) {
            final FillController fillController = fills.get(String.valueOf(annotation.getId()));
            if (fillController != null) {
                fillController.onTap();
                //  return true;
            }
        }
        // return false;
    }

    @Override
    public void onSymbolTapped(Symbol symbol) {
        final Map<String, Object> arguments = new HashMap<>(2);
        arguments.put("symbol", String.valueOf(symbol.getId()));
        methodChannel.invokeMethod("symbol#onTap", arguments);
    }

    @Override
    public void onLineTapped(Line line) {
        final Map<String, Object> arguments = new HashMap<>(2);
        arguments.put("line", String.valueOf(line.getId()));
        methodChannel.invokeMethod("line#onTap", arguments);
    }

    @Override
    public void onCircleTapped(Circle circle) {
        final Map<String, Object> arguments = new HashMap<>(2);
        arguments.put("circle", String.valueOf(circle.getId()));
        methodChannel.invokeMethod("circle#onTap", arguments);
    }

    @Override
    public void onFillTapped(Fill fill) {
        final Map<String, Object> arguments = new HashMap<>(2);
        arguments.put("fill", String.valueOf(fill.getId()));
        methodChannel.invokeMethod("fill#onTap", arguments);
    }

    @Override
    public boolean onMapClick(@NonNull LatLng point) {
        PointF pointf = mapboxMap.getProjection().toScreenLocation(point);
        final Map<String, Object> arguments = new HashMap<>(5);
        arguments.put("x", pointf.x);
        arguments.put("y", pointf.y);
        arguments.put("lng", point.getLongitude());
        arguments.put("lat", point.getLatitude());
        methodChannel.invokeMethod("map#onMapClick", arguments);

        return true;
    }

    @Override
    public boolean onMapLongClick(@NonNull LatLng point) {
        PointF pointf = mapboxMap.getProjection().toScreenLocation(point);
        final Map<String, Object> arguments = new HashMap<>(5);
        arguments.put("x", pointf.x);
        arguments.put("y", pointf.y);
        arguments.put("lng", point.getLongitude());
        arguments.put("lat", point.getLatitude());
        methodChannel.invokeMethod("map#onMapLongClick", arguments);
        return true;
    }

    @Override
    public void dispose() {
        if (disposed || registrar.activity() == null) {
            return;
        }
        disposed = true;
        if (locationComponent != null) {
            locationComponent.setLocationComponentEnabled(false);
        }
        if (symbolManager != null) {
            symbolManager.onDestroy();
        }
        if (lineManager != null) {
            lineManager.onDestroy();
        }
        if (circleManager != null) {
            circleManager.onDestroy();
        }
        if (fillManager != null) {
            fillManager.onDestroy();
        }
        stopListeningForLocationUpdates();
        mapView.onDestroy();
        registrar.activity().getApplication().unregisterActivityLifecycleCallbacks(this);
    }

    @Override
    public void onActivityCreated(Activity activity, Bundle savedInstanceState) {
        if (disposed || activity.hashCode() != registrarActivityHashCode) {
            return;
        }
        mapView.onCreate(savedInstanceState);
    }

    @Override
    public void onActivityStarted(Activity activity) {
        if (disposed || activity.hashCode() != registrarActivityHashCode) {
            return;
        }
        mapView.onStart();
    }

    @Override
    public void onActivityResumed(Activity activity) {
        if (disposed || activity.hashCode() != registrarActivityHashCode) {
            return;
        }
        mapView.onResume();
        if (myLocationEnabled) {
            startListeningForLocationUpdates();
        }
    }

    @Override
    public void onActivityPaused(Activity activity) {
        if (disposed || activity.hashCode() != registrarActivityHashCode) {
            return;
        }
        mapView.onPause();
        stopListeningForLocationUpdates();
    }

    @Override
    public void onActivityStopped(Activity activity) {
        if (disposed || activity.hashCode() != registrarActivityHashCode) {
            return;
        }
        mapView.onStop();
    }

    @Override
    public void onActivitySaveInstanceState(Activity activity, Bundle outState) {
        if (disposed || activity.hashCode() != registrarActivityHashCode) {
            return;
        }
        mapView.onSaveInstanceState(outState);
    }

    @Override
    public void onActivityDestroyed(Activity activity) {
        if (disposed || activity.hashCode() != registrarActivityHashCode) {
            return;
        }
        mapView.onDestroy();
    }

    // MapboxMapOptionsSink methods

    @Override
    public void setCameraTargetBounds(LatLngBounds bounds) {
        mapboxMap.setLatLngBoundsForCameraTarget(bounds);
    }

    @Override
    public void setCompassEnabled(boolean compassEnabled) {
        mapboxMap.getUiSettings().setCompassEnabled(compassEnabled);
    }

    @Override
    public void setTrackCameraPosition(boolean trackCameraPosition) {
        this.trackCameraPosition = trackCameraPosition;
    }

    @Override
    public void setRotateGesturesEnabled(boolean rotateGesturesEnabled) {
        mapboxMap.getUiSettings().setRotateGesturesEnabled(rotateGesturesEnabled);
    }

    @Override
    public void setScrollGesturesEnabled(boolean scrollGesturesEnabled) {
        mapboxMap.getUiSettings().setScrollGesturesEnabled(scrollGesturesEnabled);
    }

    @Override
    public void setTiltGesturesEnabled(boolean tiltGesturesEnabled) {
        mapboxMap.getUiSettings().setTiltGesturesEnabled(tiltGesturesEnabled);
    }

    @Override
    public void setMinMaxZoomPreference(Float min, Float max) {
        // VTMap.resetMinMaxZoomPreference();
        if (min != null) {
            mapboxMap.setMinZoomPreference(min);
        }
        if (max != null) {
            mapboxMap.setMaxZoomPreference(max);
        }
    }

    @Override
    public void setZoomGesturesEnabled(boolean zoomGesturesEnabled) {
        mapboxMap.getUiSettings().setZoomGesturesEnabled(zoomGesturesEnabled);
    }

    @Override
    public void setMyLocationEnabled(boolean myLocationEnabled) {
        if (this.myLocationEnabled == myLocationEnabled) {
            return;
        }
        this.myLocationEnabled = myLocationEnabled;
        if (mapboxMap != null) {
            updateMyLocationEnabled();
        }
    }

    @Override
    public void setMyLocationTrackingMode(int myLocationTrackingMode) {
        if (this.myLocationTrackingMode == myLocationTrackingMode) {
            return;
        }
        this.myLocationTrackingMode = myLocationTrackingMode;
        if (mapboxMap != null && locationComponent != null) {
            updateMyLocationTrackingMode();
        }
    }

    @Override
    public void setMyLocationRenderMode(int myLocationRenderMode) {
        if (this.myLocationRenderMode == myLocationRenderMode) {
            return;
        }
        this.myLocationRenderMode = myLocationRenderMode;
        if (mapboxMap != null && locationComponent != null) {
            updateMyLocationRenderMode();
        }
    }

    public void setLogoViewMargins(int x, int y) {
        mapboxMap.getUiSettings().setLogoMargins(x, 0, 0, y);
    }

    @Override
    public void setCompassGravity(int gravity) {
        switch (gravity) {
            case 0:
                mapboxMap.getUiSettings().setCompassGravity(Gravity.TOP | Gravity.START);
                break;
            default:
            case 1:
                mapboxMap.getUiSettings().setCompassGravity(Gravity.TOP | Gravity.END);
                break;
            case 2:
                mapboxMap.getUiSettings().setCompassGravity(Gravity.BOTTOM | Gravity.START);
                break;
            case 3:
                mapboxMap.getUiSettings().setCompassGravity(Gravity.BOTTOM | Gravity.END);
                break;
        }
    }

    @Override
    public void setCompassViewMargins(int x, int y) {
        switch (mapboxMap.getUiSettings().getCompassGravity()) {
            case Gravity.TOP | Gravity.START:
                mapboxMap.getUiSettings().setCompassMargins(x, y, 0, 0);
                break;
            default:
            case Gravity.TOP | Gravity.END:
                mapboxMap.getUiSettings().setCompassMargins(0, y, x, 0);
                break;
            case Gravity.BOTTOM | Gravity.START:
                mapboxMap.getUiSettings().setCompassMargins(x, 0, 0, y);
                break;
            case Gravity.BOTTOM | Gravity.END:
                mapboxMap.getUiSettings().setCompassMargins(0, 0, x, y);
                break;
        }
    }

    @Override
    public void setAttributionButtonMargins(int x, int y) {
        mapboxMap.getUiSettings().setAttributionMargins(0, 0, x, y);
    }

    @Override
    public void setGPSControlEnable(Boolean enable) {
        this.myGPSControlEnabled = enable;
        if (enable && mapboxMap != null) {
            LocationControl locationControl = new LocationControl(mapView, mapboxMap);
            locationControl.addToMap(context);
        }

    }

    @Override
    public void setMapTypeControlEnable(Boolean enable) {
        this.myMapTypeControlEnabled = enable;
        if (enable && mapboxMap != null) {
            MapTypeControl mapTypeControl = new MapTypeControl(mapView, mapboxMap);
            mapTypeControl.addToMap(context);
        }

    }

    @Override
    public void setLogoEnable(Boolean enable) {
        this.logoEnable = enable;
        if (mapboxMap != null) {
            mapboxMap.getUiSettings().setLogoEnabled(enable);
        }
    }

    private void updateMyLocationEnabled() {
        if (this.locationComponent == null && myLocationEnabled) {
            enableLocationComponent(mapboxMap.getStyle());
        }

        if (myLocationEnabled) {
            startListeningForLocationUpdates();
        } else {
            stopListeningForLocationUpdates();
        }

        locationComponent.setLocationComponentEnabled(myLocationEnabled);
    }

    private void startListeningForLocationUpdates() {
        if (locationEngineCallback == null && locationComponent != null && locationComponent.getLocationEngine() != null) {
            locationEngineCallback = new LocationEngineCallback<LocationEngineResult>() {
                @Override
                public void onSuccess(LocationEngineResult result) {
                    onUserLocationUpdate(result.getLastLocation());
                }

                @Override
                public void onFailure(@NonNull Exception exception) {
                }
            };
            locationComponent.getLocationEngine().requestLocationUpdates(locationComponent.getLocationEngineRequest(), locationEngineCallback, null);
        }
    }

    private void stopListeningForLocationUpdates() {
        if (locationEngineCallback != null && locationComponent != null && locationComponent.getLocationEngine() != null) {
            locationComponent.getLocationEngine().removeLocationUpdates(locationEngineCallback);
            locationEngineCallback = null;
        }
    }

    private void updateMyLocationTrackingMode() {
        int[] mapboxTrackingModes = new int[]{CameraMode.NONE, CameraMode.TRACKING, CameraMode.TRACKING_COMPASS, CameraMode.TRACKING_GPS};
        locationComponent.setCameraMode(mapboxTrackingModes[this.myLocationTrackingMode]);
    }

    private void updateMyLocationRenderMode() {
        int[] mapboxRenderModes = new int[]{RenderMode.NORMAL, RenderMode.COMPASS, RenderMode.GPS};
        locationComponent.setRenderMode(mapboxRenderModes[this.myLocationRenderMode]);
    }

    private boolean hasLocationPermission() {
        return checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION)
                == PackageManager.PERMISSION_GRANTED
                || checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION)
                == PackageManager.PERMISSION_GRANTED;
    }

    private int checkSelfPermission(String permission) {
        if (permission == null) {
            throw new IllegalArgumentException("permission is null");
        }
        return context.checkPermission(
                permission, android.os.Process.myPid(), android.os.Process.myUid());
    }

    /**
     * Tries to find highest scale image for display type
     *
     * @param imageId
     * @param density
     * @return
     */
    private Bitmap getScaledImage(String imageId, float density) {
        AssetManager assetManager = registrar.context().getAssets();
        AssetFileDescriptor assetFileDescriptor = null;

        // Split image path into parts.
        List<String> imagePathList = Arrays.asList(imageId.split("/"));
        List<String> assetPathList = new ArrayList<>();

        // "On devices with a device pixel ratio of 1.8, the asset .../2.0x/my_icon.png would be chosen.
        // For a device pixel ratio of 2.7, the asset .../3.0x/my_icon.png would be chosen."
        // Source: https://flutter.dev/docs/development/ui/assets-and-images#resolution-aware
        for (int i = (int) Math.ceil(density); i > 0; i--) {
            String assetPath;
            if (i == 1) {
                // If density is 1.0x then simply take the default asset path
                assetPath = registrar.lookupKeyForAsset(imageId);
            } else {
                // Build a resolution aware asset path as follows:
                // <directory asset>/<ratio>/<image name>
                // where ratio is 1.0x, 2.0x or 3.0x.
                StringBuilder stringBuilder = new StringBuilder();
                for (int j = 0; j < imagePathList.size() - 1; j++) {
                    stringBuilder.append(imagePathList.get(j));
                    stringBuilder.append("/");
                }
                stringBuilder.append(((float) i) + "x");
                stringBuilder.append("/");
                stringBuilder.append(imagePathList.get(imagePathList.size() - 1));
                assetPath = registrar.lookupKeyForAsset(stringBuilder.toString());
            }
            // Build up a list of resolution aware asset paths.
            assetPathList.add(assetPath);
        }

        // Iterate over asset paths and get the highest scaled asset (as a bitmap).
        Bitmap bitmap = null;
        for (String assetPath : assetPathList) {
            try {
                // Read path (throws exception if doesn't exist).
                assetFileDescriptor = assetManager.openFd(assetPath);
                InputStream assetStream = assetFileDescriptor.createInputStream();
                bitmap = BitmapFactory.decodeStream(assetStream);
                assetFileDescriptor.close(); // Close for memory
                break; // If exists, break
            } catch (IOException e) {
                // Skip
            }
        }
        return bitmap;
    }

    /**
     * Simple Listener to listen for the status of camera movements.
     */
    public class OnCameraMoveFinishedListener implements VTMap.CancelableCallback {
        @Override
        public void onFinish() {
        }

        @Override
        public void onCancel() {
        }
    }
}