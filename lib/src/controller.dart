// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of vtmap_gl;

typedef void OnMapClickCallback(Point<double>? point, LatLng? coordinates);
typedef void OnMapLongClickCallback(Point<double>? point, LatLng? coordinates);

typedef void OnStyleLoadedCallback();

typedef void OnUserLocationUpdated(UserLocation location);

typedef void OnCameraTrackingDismissedCallback();
typedef void OnCameraTrackingChangedCallback(MyLocationTrackingMode mode);

typedef void OnCameraIdleCallback();

typedef void OnMapIdleCallback();

typedef void OnCameraMovingStartedCallBack();

/// Controller for a single MapboxMap instance running on the host platform.
///
/// Change listeners are notified upon changes to any of
///
/// * the [options] property
/// * the collection of [Symbol]s added to this map
/// * the collection of [Line]s added to this map
/// * the [isCameraMoving] property
/// * the [cameraPosition] property
///
/// Listeners are notified after changes have been applied on the platform side.
///
/// Symbol tap events can be received by adding callbacks to [onSymbolTapped].
/// Line tap events can be received by adding callbacks to [onLineTapped].
/// Circle tap events can be received by adding callbacks to [onCircleTapped].
class MapboxMapController extends ChangeNotifier {
  MapboxMapController._(this._id, CameraPosition initialCameraPosition,
      {this.onStyleLoadedCallback,
      this.onMapClick,
      this.onMapLongClick,
      this.onCameraTrackingDismissed,
      this.onCameraTrackingChanged,
      this.onMapIdle,
      this.onUserLocationUpdated,
      this.onCameraIdle,
      this.onCameraMovingStarted})
      : assert(_id != null) {
    _cameraPosition = initialCameraPosition;

    MapboxGlPlatform.getInstance(_id)!
        .onInfoWindowTappedPlatform
        .add((symbolId) {
      final Symbol? symbol = _symbols[symbolId];
      if (symbol != null) {
        onInfoWindowTapped(symbol);
      }
    });

    MapboxGlPlatform.getInstance(_id)!.onSymbolTappedPlatform.add((symbolId) {
      final Symbol? symbol = _symbols[symbolId];
      if (symbol != null) {
        onSymbolTapped(symbol);
      }
    });

    MapboxGlPlatform.getInstance(_id)!.onLineTappedPlatform.add((lineId) {
      final Line? line = _lines[lineId];
      if (line != null) {
        onLineTapped(line);
      }
    });

    MapboxGlPlatform.getInstance(_id)!.onCircleTappedPlatform.add((circleId) {
      final Circle? circle = _circles[circleId];
      if (circle != null) {
        onCircleTapped(circle);
      }
    });

    MapboxGlPlatform.getInstance(_id)!.onFillTappedPlatform.add((fillId) {
      final Fill? fill = _fills[fillId];
      if (fill != null) {
        onFillTapped(fill);
      }
    });

    MapboxGlPlatform.getInstance(_id)!.onRouteSelected.add((index) {
      onRouteSelected(index);
    });

    MapboxGlPlatform.getInstance(_id)!.onCameraMoveStartedPlatform.add((_) {
      _isCameraMoving = true;
      if (onCameraMovingStarted != null) {
        onCameraMovingStarted!();
      }
      notifyListeners();
    });

    MapboxGlPlatform.getInstance(_id)!
        .onCameraMovePlatform
        .add((cameraPosition) {
      _cameraPosition = cameraPosition;
      notifyListeners();
    });

    MapboxGlPlatform.getInstance(_id)!.onCameraIdlePlatform.add((_) {
      _isCameraMoving = false;
      if (onCameraIdle != null) {
        onCameraIdle!();
      }
      notifyListeners();
    });

    MapboxGlPlatform.getInstance(_id)!.onMapStyleLoadedPlatform.add((_) {
      if (onStyleLoadedCallback != null) {
        onStyleLoadedCallback!();
      }
    });

    MapboxGlPlatform.getInstance(_id)!.onMapClickPlatform.add((dict) {
      if (onMapClick != null) {
        onMapClick!(dict['point'], dict['latLng']);
      }
    });

    MapboxGlPlatform.getInstance(_id)!.onMapLongClickPlatform.add((dict) {
      if (onMapLongClick != null) {
        onMapLongClick!(dict['point'], dict['latLng']);
      }
    });

    MapboxGlPlatform.getInstance(_id)!
        .onCameraTrackingChangedPlatform
        .add((mode) {
      if (onCameraTrackingChanged != null) {
        onCameraTrackingChanged!(mode);
      }
    });

    MapboxGlPlatform.getInstance(_id)!
        .onCameraTrackingDismissedPlatform
        .add((_) {
      if (onCameraTrackingDismissed != null) {
        onCameraTrackingDismissed!();
      }
    });

    MapboxGlPlatform.getInstance(_id)!.onMapIdlePlatform.add((_) {
      if (onMapIdle != null) {
        onMapIdle!();
      }
    });
    MapboxGlPlatform.getInstance(_id)!
        .onUserLocationUpdatedPlatform
        .add((location) {
      onUserLocationUpdated?.call(location);
    });
  }

  static MapboxMapController init(int id, CameraPosition initialCameraPosition,
      {OnStyleLoadedCallback? onStyleLoadedCallback,
      OnMapClickCallback? onMapClick,
      OnUserLocationUpdated? onUserLocationUpdated,
      OnMapLongClickCallback? onMapLongClick,
      OnCameraTrackingDismissedCallback? onCameraTrackingDismissed,
      OnCameraTrackingChangedCallback? onCameraTrackingChanged,
      OnCameraIdleCallback? onCameraIdle,
      OnMapIdleCallback? onMapIdle,
      OnCameraMovingStartedCallBack? onCameraMovingStarted}) {
    assert(id != null);
    return MapboxMapController._(id, initialCameraPosition,
        onStyleLoadedCallback: onStyleLoadedCallback,
        onMapClick: onMapClick,
        onUserLocationUpdated: onUserLocationUpdated,
        onMapLongClick: onMapLongClick,
        onCameraTrackingDismissed: onCameraTrackingDismissed,
        onCameraTrackingChanged: onCameraTrackingChanged,
        onCameraIdle: onCameraIdle,
        onMapIdle: onMapIdle,
        onCameraMovingStarted: onCameraMovingStarted);
  }

  static Future<void> initPlatform(int id) async {
    assert(id != null);
    await MapboxGlPlatform.getInstance(id)!.initPlatform(id);
  }

  final OnStyleLoadedCallback? onStyleLoadedCallback;

  final OnMapClickCallback? onMapClick;
  final OnMapLongClickCallback? onMapLongClick;

  final OnUserLocationUpdated? onUserLocationUpdated;

  final OnCameraTrackingDismissedCallback? onCameraTrackingDismissed;
  final OnCameraTrackingChangedCallback? onCameraTrackingChanged;

  final OnCameraIdleCallback? onCameraIdle;

  final OnCameraIdleCallback? onCameraMovingStarted;

  final OnMapIdleCallback? onMapIdle;

  /// Callbacks to receive tap events for symbols placed on this map.
  final ArgumentCallbacks<Symbol> onSymbolTapped = ArgumentCallbacks<Symbol>();

  /// Callbacks to receive tap events for symbols placed on this map.
  final ArgumentCallbacks<Circle> onCircleTapped = ArgumentCallbacks<Circle>();

  /// Callbacks to receive tap events for fills placed on this map.
  final ArgumentCallbacks<Fill> onFillTapped = ArgumentCallbacks<Fill>();

  /// Callbacks to receive tap events for info windows on symbols
  final ArgumentCallbacks<Symbol> onInfoWindowTapped =
      ArgumentCallbacks<Symbol>();

  final ArgumentCallbacks<int> onRouteSelected = ArgumentCallbacks<int>();

  /// The current set of symbols on this map.
  ///
  /// The returned set will be a detached snapshot of the symbols collection.
  Set<Symbol> get symbols => Set<Symbol>.from(_symbols.values);
  final Map<String, Symbol> _symbols = <String, Symbol>{};

  /// Callbacks to receive tap events for lines placed on this map.
  final ArgumentCallbacks<Line> onLineTapped = ArgumentCallbacks<Line>();

  /// The current set of lines on this map.
  ///
  /// The returned set will be a detached snapshot of the lines collection.
  Set<Line> get lines => Set<Line>.from(_lines.values);
  final Map<String?, Line> _lines = <String?, Line>{};

  /// The current set of circles on this map.
  ///
  /// The returned set will be a detached snapshot of the circles collection.
  Set<Circle> get circles => Set<Circle>.from(_circles.values);
  final Map<String?, Circle> _circles = <String?, Circle>{};

  /// The current set of fills on this map.
  ///
  /// The returned set will be a detached snapshot of the fills collection.
  Set<Fill> get fills => Set<Fill>.from(_fills.values);
  final Map<String?, Fill> _fills = <String?, Fill>{};

  /// True if the map camera is currently moving.
  bool get isCameraMoving => _isCameraMoving;
  bool _isCameraMoving = false;

  /// Returns the most recent camera position reported by the platform side.
  /// Will be null, if [MapboxMap.trackCameraPosition] is false.
  CameraPosition? get cameraPosition => _cameraPosition;
  CameraPosition? _cameraPosition;

  final int _id; //ignore: unused_field

  Widget buildView(
      Map<String, dynamic> creationParams,
      Function onPlatformViewCreated,
      Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers) {
    return MapboxGlPlatform.getInstance(_id)!
        .buildView(creationParams, onPlatformViewCreated, gestureRecognizers);
  }

  /// Updates configuration options of the map user interface.
  ///
  /// Change listeners are notified once the update has been made on the
  /// platform side.
  ///
  /// The returned [Future] completes after listeners have been notified.
  Future<void> _updateMapOptions(Map<String, dynamic> optionsUpdate) async {
    assert(optionsUpdate != null);
    _cameraPosition = await MapboxGlPlatform.getInstance(_id)!
        .updateMapOptions(optionsUpdate);
    notifyListeners();
  }

  /// Starts an animated change of the map camera position.
  ///
  /// The returned [Future] completes after the change has been started on the
  /// platform side.
  /// It returns true if the camera was successfully moved and false if the movement was canceled.
  /// Note: this currently always returns immediately with a value of null on iOS
  Future<bool?> animateCamera(
      {required CameraUpdate cameraUpdate, int? duration}) async {
    assert(cameraUpdate != null);
    Map<String, dynamic> args = Map<String, dynamic>();
    args["duration"] = duration;
    args["cameraUpdate"] = cameraUpdate.toJson();
    return MapboxGlPlatform.getInstance(_id)!.animateCamera(args);
  }

  /// Instantaneously re-position the camera.
  /// Note: moveCamera() quickly moves the camera, which can be visually jarring for a user. Strongly consider using the animateCamera() methods instead because it's less abrupt.
  ///
  /// The returned [Future] completes after the change has been made on the
  /// platform side.
  /// It returns true if the camera was successfully moved and false if the movement was canceled.
  /// Note: this currently always returns immediately with a value of null on iOS
  Future<bool?> moveCamera(CameraUpdate cameraUpdate) async {
    return MapboxGlPlatform.getInstance(_id)!.moveCamera(cameraUpdate);
  }

  /// Updates user location tracking mode.
  ///
  /// The returned [Future] completes after the change has been made on the
  /// platform side.
  Future<void> updateMyLocationTrackingMode(
      MyLocationTrackingMode myLocationTrackingMode) async {
    return MapboxGlPlatform.getInstance(_id)!
        .updateMyLocationTrackingMode(myLocationTrackingMode);
  }

  /// Updates the language of the map labels to match the device's language.
  ///
  /// The returned [Future] completes after the change has been made on the
  /// platform side.
  Future<void> matchMapLanguageWithDeviceDefault() async {
    return MapboxGlPlatform.getInstance(_id)!
        .matchMapLanguageWithDeviceDefault();
  }

  /// Updates the distance from the edges of the map view’s frame to the edges
  /// of the map view’s logical viewport, optionally animating the change.
  ///
  /// When the value of this property is equal to `EdgeInsets.zero`, viewport
  /// properties such as centerCoordinate assume a viewport that matches the map
  /// view’s frame. Otherwise, those properties are inset, excluding part of the
  /// frame from the viewport. For instance, if the only the top edge is inset,
  /// the map center is effectively shifted downward.
  ///
  /// The returned [Future] completes after the change has been made on the
  /// platform side.
  Future<void> updateContentInsets(EdgeInsets insets,
      [bool animated = false]) async {
    return MapboxGlPlatform.getInstance(_id)!
        .updateContentInsets(insets, animated);
  }

  /// Updates the language of the map labels to match the specified language.
  /// Supported language strings are available here: https://github.com/mapbox/mapbox-plugins-android/blob/e29c18d25098eb023a831796ff807e30d8207c36/plugin-localization/src/main/java/com/mapbox/mapboxsdk/plugins/localization/MapLocale.java#L39-L87
  ///
  /// The returned [Future] completes after the change has been made on the
  /// platform side.
  Future<void> setMapLanguage(String language) async {
    return MapboxGlPlatform.getInstance(_id)!.setMapLanguage(language);
  }

  /// Enables or disables the collection of anonymized telemetry data.
  ///
  /// The returned [Future] completes after the change has been made on the
  /// platform side.
  Future<void> setTelemetryEnabled(bool enabled) async {
    return MapboxGlPlatform.getInstance(_id)!.setTelemetryEnabled(enabled);
  }

  /// Retrieves whether collection of anonymized telemetry data is enabled.
  ///
  /// The returned [Future] completes after the query has been made on the
  /// platform side.
  Future<bool?> getTelemetryEnabled() async {
    return MapboxGlPlatform.getInstance(_id)!.getTelemetryEnabled();
  }

  /// Adds a symbol to the map, configured using the specified custom [options].
  ///
  /// Change listeners are notified once the symbol has been added on the
  /// platform side.
  ///
  /// The returned [Future] completes with the added symbol once listeners have
  /// been notified.
  Future<Symbol> addSymbol(SymbolOptions options, [Map? data]) async {
    List<Symbol> result = await addSymbols([options], [data]);

    return result.first;
  }

  Future<List<Symbol>> addSymbols(List<SymbolOptions> options,
      [List<Map?>? data]) async {
    final List<SymbolOptions> effectiveOptions =
        options.map((o) => SymbolOptions.defaultOptions.copyWith(o)).toList();

    final symbols = await MapboxGlPlatform.getInstance(_id)!
        .addSymbols(effectiveOptions, data);
    symbols.forEach((s) => _symbols[s.id] = s);
    notifyListeners();
    return symbols;
  }

  /// Updates the specified [symbol] with the given [changes]. The symbol must
  /// be a current member of the [symbols] set.
  ///
  /// Change listeners are notified once the symbol has been updated on the
  /// platform side.
  ///
  /// The returned [Future] completes once listeners have been notified.
  Future<void> updateSymbol(Symbol symbol, SymbolOptions changes) async {
    assert(symbol != null);
    assert(_symbols[symbol.id] == symbol);
    assert(changes != null);
    await MapboxGlPlatform.getInstance(_id)!.updateSymbol(symbol, changes);
    symbol.options = symbol.options.copyWith(changes);
    notifyListeners();
  }

  /// Retrieves the current position of the symbol.
  /// This may be different from the value of `symbol.options.geometry` if the symbol is draggable.
  /// In that case this method provides the symbol's actual position, and `symbol.options.geometry` the last programmatically set position.
  Future<LatLng> getSymbolLatLng(Symbol symbol) async {
    assert(symbol != null);
    assert(_symbols[symbol.id] == symbol);
    final symbolLatLng =
        await MapboxGlPlatform.getInstance(_id)!.getSymbolLatLng(symbol);
    notifyListeners();
    return symbolLatLng;
  }

  /// Removes the specified [symbol] from the map. The symbol must be a current
  /// member of the [symbols] set.
  ///
  /// Change listeners are notified once the symbol has been removed on the
  /// platform side.
  ///
  /// The returned [Future] completes once listeners have been notified.
  Future<void> removeSymbol(Symbol symbol) async {
    assert(symbol != null);
    assert(_symbols[symbol.id] == symbol);
    await _removeSymbols([symbol.id]);
    notifyListeners();
  }

  Future<void> removeSymbols(Iterable<Symbol> symbols) async {
    assert(symbols.length > 0);
    symbols.forEach((s) {
      assert(_symbols[s.id] == s);
    });

    await _removeSymbols(symbols.map((s) => s.id));
    notifyListeners();
  }

  /// Removes all [symbols] from the map.
  ///
  /// Change listeners are notified once all symbols have been removed on the
  /// platform side.
  ///
  /// The returned [Future] completes once listeners have been notified.
  Future<void> clearSymbols() async {
    assert(_symbols != null);
    final List<String> symbolIds = List<String>.from(_symbols.keys);
    _removeSymbols(symbolIds);
    notifyListeners();
  }

  /// Helper method to remove a single symbol from the map. Consumed by
  /// [removeSymbol] and [clearSymbols].
  ///
  /// The returned [Future] completes once the symbol has been removed from
  /// [_symbols].
  Future<void> _removeSymbols(Iterable<String> ids) async {
    await MapboxGlPlatform.getInstance(_id)!.removeSymbols(ids);
    _symbols.removeWhere((k, s) => ids.contains(k));
  }

  /// Adds a line to the map, configured using the specified custom [options].
  ///
  /// Change listeners are notified once the line has been added on the
  /// platform side.
  ///
  /// The returned [Future] completes with the added line once listeners have
  /// been notified.
  Future<Line> addLine(LineOptions options, [Map? data]) async {
    final LineOptions effectiveOptions =
        LineOptions.defaultOptions.copyWith(options);
    final line = await MapboxGlPlatform.getInstance(_id)!
        .addLine(effectiveOptions, data);
    _lines[line.id] = line;
    notifyListeners();
    return line;
  }

  /// Updates the specified [line] with the given [changes]. The line must
  /// be a current member of the [lines] set.
  ///
  /// Change listeners are notified once the line has been updated on the
  /// platform side.
  ///
  /// The returned [Future] completes once listeners have been notified.
  Future<void> updateLine(Line line, LineOptions changes) async {
    assert(line != null);
    assert(_lines[line.id] == line);
    assert(changes != null);
    await MapboxGlPlatform.getInstance(_id)!.updateLine(line, changes);
    line.options = line.options.copyWith(changes);
    notifyListeners();
  }

  /// Retrieves the current position of the line.
  /// This may be different from the value of `line.options.geometry` if the line is draggable.
  /// In that case this method provides the line's actual position, and `line.options.geometry` the last programmatically set position.
  Future<List<LatLng>> getLineLatLngs(Line line) async {
    assert(line != null);
    assert(_lines[line.id] == line);
    final lineLatLngs =
        await MapboxGlPlatform.getInstance(_id)!.getLineLatLngs(line);
    notifyListeners();
    return lineLatLngs;
  }

  /// Removes the specified [line] from the map. The line must be a current
  /// member of the [lines] set.
  ///
  /// Change listeners are notified once the line has been removed on the
  /// platform side.
  ///
  /// The returned [Future] completes once listeners have been notified.
  Future<void> removeLine(Line line) async {
    assert(line != null);
    assert(_lines[line.id] == line);
    await _removeLine(line.id!);
    notifyListeners();
  }

  /// Removes all [lines] from the map.
  ///
  /// Change listeners are notified once all lines have been removed on the
  /// platform side.
  ///
  /// The returned [Future] completes once listeners have been notified.
  Future<void> clearLines() async {
    assert(_lines != null);
    final List<String> lineIds = List<String>.from(_lines.keys);
    for (String id in lineIds) {
      await _removeLine(id);
    }
    notifyListeners();
  }

  /// Helper method to remove a single line from the map. Consumed by
  /// [removeLine] and [clearLines].
  ///
  /// The returned [Future] completes once the line has been removed from
  /// [_lines].
  Future<void> _removeLine(String id) async {
    await MapboxGlPlatform.getInstance(_id)!.removeLine(id);
    _lines.remove(id);
  }

  /// Adds a circle to the map, configured using the specified custom [options].
  ///
  /// Change listeners are notified once the circle has been added on the
  /// platform side.
  ///
  /// The returned [Future] completes with the added circle once listeners have
  /// been notified.
  Future<Circle> addCircle(CircleOptions options, [Map? data]) async {
    final CircleOptions effectiveOptions =
        CircleOptions.defaultOptions.copyWith(options);
    final circle = await MapboxGlPlatform.getInstance(_id)!
        .addCircle(effectiveOptions, data);
    _circles[circle.id] = circle;
    notifyListeners();
    return circle;
  }

  /// Updates the specified [circle] with the given [changes]. The circle must
  /// be a current member of the [circles] set.
  ///
  /// Change listeners are notified once the circle has been updated on the
  /// platform side.
  ///
  /// The returned [Future] completes once listeners have been notified.
  Future<void> updateCircle(Circle circle, CircleOptions changes) async {
    assert(circle != null);
    assert(_circles[circle.id] == circle);
    assert(changes != null);
    await MapboxGlPlatform.getInstance(_id)!.updateCircle(circle, changes);
    circle.options = circle.options.copyWith(changes);
    notifyListeners();
  }

  /// Retrieves the current position of the circle.
  /// This may be different from the value of `circle.options.geometry` if the circle is draggable.
  /// In that case this method provides the circle's actual position, and `circle.options.geometry` the last programmatically set position.
  Future<LatLng> getCircleLatLng(Circle circle) async {
    assert(circle != null);
    assert(_circles[circle.id] == circle);
    final circleLatLng =
        await MapboxGlPlatform.getInstance(_id)!.getCircleLatLng(circle);
    notifyListeners();
    return circleLatLng;
  }

  /// Removes the specified [circle] from the map. The circle must be a current
  /// member of the [circles] set.
  ///
  /// Change listeners are notified once the circle has been removed on the
  /// platform side.
  ///
  /// The returned [Future] completes once listeners have been notified.
  Future<void> removeCircle(Circle circle) async {
    assert(circle != null);
    assert(_circles[circle.id] == circle);
    await _removeCircle(circle.id!);
    notifyListeners();
  }

  /// Removes all [circles] from the map.
  ///
  /// Change listeners are notified once all circles have been removed on the
  /// platform side.
  ///
  /// The returned [Future] completes once listeners have been notified.
  Future<void> clearCircles() async {
    assert(_circles != null);
    final List<String> circleIds = List<String>.from(_circles.keys);
    for (String id in circleIds) {
      await _removeCircle(id);
    }
    notifyListeners();
  }

  /// Helper method to remove a single circle from the map. Consumed by
  /// [removeCircle] and [clearCircles].
  ///
  /// The returned [Future] completes once the circle has been removed from
  /// [_circles].
  Future<void> _removeCircle(String id) async {
    await MapboxGlPlatform.getInstance(_id)!.removeCircle(id);

    _circles.remove(id);
  }

  /// Adds a fill to the map, configured using the specified custom [options].
  ///
  /// Change listeners are notified once the fill has been added on the
  /// platform side.
  ///
  /// The returned [Future] completes with the added fill once listeners have
  /// been notified.
  Future<Fill> addFill(FillOptions options, [Map? data]) async {
    final FillOptions effectiveOptions =
        FillOptions.defaultOptions.copyWith(options);
    final fill =
        await MapboxGlPlatform.getInstance(_id)!.addFill(effectiveOptions);
    _fills[fill.id] = fill;
    notifyListeners();
    return fill;
  }

  /// Updates the specified [fill] with the given [changes]. The fill must
  /// be a current member of the [fills] set.
  ///
  /// Change listeners are notified once the fill has been updated on the
  /// platform side.
  ///
  /// The returned [Future] completes once listeners have been notified.
  Future<void> updateFill(Fill fill, FillOptions changes) async {
    assert(fill != null);
    assert(_fills[fill.id] == fill);
    assert(changes != null);
    await MapboxGlPlatform.getInstance(_id)!.updateFill(fill, changes);
    fill.options = fill.options.copyWith(changes);
    notifyListeners();
  }

  /// Removes the specified [fill] from the map. The fill must be a current
  /// member of the [fills] set.
  ///
  /// Change listeners are notified once the fill has been removed on the
  /// platform side.
  ///
  /// The returned [Future] completes once listeners have been notified.
  Future<void> removeFill(Fill fill) async {
    assert(fill != null);
    assert(_fills[fill.id] == fill);
    await _removeFill(fill.id!);
    notifyListeners();
  }

  /// Helper method to remove a single fill from the map. Consumed by
  /// [removeFill] and [clearFills].
  ///
  /// The returned [Future] completes once the fill has been removed from
  /// [_fills].
  Future<void> _removeFill(String id) async {
    await MapboxGlPlatform.getInstance(_id)!.removeFill(id);

    _fills.remove(id);
  }

  Future<List?> queryRenderedFeatures(
      Point<double> point, List<String> layerIds, List<Object>? filter) async {
    return MapboxGlPlatform.getInstance(_id)!
        .queryRenderedFeatures(point, layerIds, filter!);
  }

  Future<List?> queryRenderedFeaturesInRect(
      Rect rect, List<String> layerIds, String filter) async {
    return MapboxGlPlatform.getInstance(_id)!
        .queryRenderedFeaturesInRect(rect, layerIds, filter);
  }

  Future invalidateAmbientCache() async {
    return MapboxGlPlatform.getInstance(_id)!.invalidateAmbientCache();
  }

  /// Get last my location
  ///
  /// Return last latlng, nullable
  Future<LatLng> requestMyLocationLatLng() async {
    return MapboxGlPlatform.getInstance(_id)!.requestMyLocationLatLng();
  }

  /// This method returns the boundaries of the region currently displayed in the map.
  Future<LatLngBounds> getVisibleRegion() async {
    return MapboxGlPlatform.getInstance(_id)!.getVisibleRegion();
  }

  /// Adds an image to the style currently displayed in the map, so that it can later be referred to by the provided name.
  ///
  /// This allows you to add an image to the currently displayed style once, and from there on refer to it e.g. in the [Symbol.iconImage] anytime you add a [Symbol] later on.
  /// Set [sdf] to true if the image you add is an SDF image.
  /// Returns after the image has successfully been added to the style.
  /// Note: This can only be called after OnStyleLoadedCallback has been invoked and any added images will have to be re-added if a new style is loaded.
  ///
  /// Example: Adding an asset image and using it in a new symbol:
  /// ```dart
  /// Future<void> addImageFromAsset() async{
  ///   final ByteData bytes = await rootBundle.load("assets/someAssetImage.jpg");
  ///   final Uint8List list = bytes.buffer.asUint8List();
  ///   await controller.addImage("assetImage", list);
  ///   controller.addSymbol(
  ///    SymbolOptions(
  ///     geometry: LatLng(0,0),
  ///     iconImage: "assetImage",
  ///    ),
  ///   );
  /// }
  /// ```
  ///
  /// Example: Adding a network image (with the http package) and using it in a new symbol:
  /// ```dart
  /// Future<void> addImageFromUrl() async{
  ///  var response = await get("https://example.com/image.png");
  ///  await controller.addImage("testImage",  response.bodyBytes);
  ///  controller.addSymbol(
  ///   SymbolOptions(
  ///     geometry: LatLng(0,0),
  ///     iconImage: "testImage",
  ///   ),
  ///  );
  /// }
  /// ```
  Future<void> addImage(String name, Uint8List bytes, [bool sdf = false]) {
    return MapboxGlPlatform.getInstance(_id)!.addImage(name, bytes, sdf);
  }

  /// For more information on what this does, see https://docs.mapbox.com/help/troubleshooting/optimize-map-label-placement/#label-collision
  Future<void> setSymbolIconAllowOverlap(bool enable) async {
    await MapboxGlPlatform.getInstance(_id)!.setSymbolIconAllowOverlap(enable);
  }

  /// For more information on what this does, see https://docs.mapbox.com/help/troubleshooting/optimize-map-label-placement/#label-collision
  Future<void> setSymbolIconIgnorePlacement(bool enable) async {
    await MapboxGlPlatform.getInstance(_id)!
        .setSymbolIconIgnorePlacement(enable);
  }

  /// For more information on what this does, see https://docs.mapbox.com/help/troubleshooting/optimize-map-label-placement/#label-collision
  Future<void> setSymbolTextAllowOverlap(bool enable) async {
    await MapboxGlPlatform.getInstance(_id)!.setSymbolTextAllowOverlap(enable);
  }

  /// For more information on what this does, see https://docs.mapbox.com/help/troubleshooting/optimize-map-label-placement/#label-collision
  Future<void> setSymbolTextIgnorePlacement(bool enable) async {
    await MapboxGlPlatform.getInstance(_id)!
        .setSymbolTextIgnorePlacement(enable);
  }

  /// Adds an image source to the style currently displayed in the map, so that it can later be referred to by the provided name.
  Future<void> addImageSource(
      String name, Uint8List bytes, LatLngQuad coordinates) {
    return MapboxGlPlatform.getInstance(_id)!
        .addImageSource(name, bytes, coordinates);
  }

  /// Removes previously added image source by name
  Future<void> removeImageSource(String name) {
    return MapboxGlPlatform.getInstance(_id)!.removeImageSource(name);
  }

  /// Adds layer with name
  Future<void> addLayer(String name, String sourceId) {
    return MapboxGlPlatform.getInstance(_id)!.addLayer(name, sourceId);
  }

  /// Removes layer by name
  Future<void> removeLayer(String name) {
    return MapboxGlPlatform.getInstance(_id)!.removeLayer(name);
  }

  /// Returns the point on the screen that corresponds to a geographical coordinate ([latLng]). The screen location is in screen pixels (not display pixels) relative to the top left of the map (not of the whole screen)
  ///
  /// Note: The resulting x and y coordinates are rounded to [int] on web, on other platforms they may differ very slightly (in the range of about 10^-10) from the actual nearest screen coordinate.
  /// You therefore might want to round them appropriately, depending on your use case.
  ///
  /// Returns null if [latLng] is not currently visible on the map.
  Future<Point> toScreenLocation(LatLng latLng) async {
    return MapboxGlPlatform.getInstance(_id)!.toScreenLocation(latLng);
  }

  /// Returns the geographic location (as [LatLng]) that corresponds to a point on the screen. The screen location is specified in screen pixels (not display pixels) relative to the top left of the map (not the top left of the whole screen).
  Future<LatLng> toLatLng(Point screenLocation) async {
    return MapboxGlPlatform.getInstance(_id)!.toLatLng(screenLocation);
  }

  /// Returns the distance spanned by one pixel at the specified [latitude] and current zoom level.
  /// The distance between pixels decreases as the latitude approaches the poles. This relationship parallels the relationship between longitudinal coordinates at different latitudes.
  Future<double?> getMetersPerPixelAtLatitude(double latitude) async {
    return MapboxGlPlatform.getInstance(_id)!
        .getMetersPerPixelAtLatitude(latitude);
  }

  ///Build the Route Used for the Navigation
  ///
  /// [wayPoints] must not be null. A collection of [WayPoint](longitude, latitude and name). Must be at least 2 or at most 25. Cannot use drivingWithTraffic mode if more than 3-waypoints.
  /// [options] options used to generate the route and used while navigating
  ///
  Future<bool?> buildRoute(
      {required List<WayPoint> wayPoints, VTMapOptions? options}) async {
    assert(wayPoints != null);
    assert(wayPoints.length > 1);
    // if (Platform.isIOS && wayPoints.length > 3 && options?.mode != null) {
    //   assert(options.mode != VTMapNavigationMode.drivingWithTraffic,
    //       "Error: Cannot use drivingWithTraffic Mode when you have more than 3 Stops");
    // }
    List<Map<String, Object?>> pointList = <Map<String, Object?>>[];

    for (int i = 0; i < wayPoints.length; i++) {
      var wayPoint = wayPoints[i];
      assert(wayPoint != null);
      assert(wayPoint.name != null);
      assert(wayPoint.latitude != null);
      assert(wayPoint.longitude != null);

      final pointMap = <String, dynamic>{
        "Order": i,
        "Name": wayPoint.name,
        "Latitude": wayPoint.latitude,
        "Longitude": wayPoint.longitude,
      };

      print(wayPoints[i].latitude);

      pointList.add(pointMap);
    }
    var i = 0;
    var wayPointMap =
        Map.fromIterable(pointList, key: (e) => i++, value: (e) => e);

    Map<String, dynamic> args = Map<String, dynamic>();
    if (options != null) args = options.toMap();
    args["wayPoints"] = wayPointMap;

    // _routeEventSubscription = _streamRouteEvent.listen(_onProgressData);
    return await MapboxGlPlatform.getInstance(_id)!.buildRoute(args);
    // return await _methodChannel
    //     .invokeMethod('buildRoute', args)
    //     .then<bool>((dynamic result) => result);
  }

  Future startNavigation(
      {required List<WayPoint> wayPoints,
      required VTMapOptions options}) async {
    assert(wayPoints != null);
    assert(wayPoints.length > 1);

    List<Map<String, dynamic?>> pointList = <Map<String, dynamic>>[];

    for (int i = 0; i < wayPoints.length; i++) {
      var wayPoint = wayPoints[i];
      assert(wayPoint != null);
      assert(wayPoint.name != null);
      assert(wayPoint.latitude != null);
      assert(wayPoint.longitude != null);

      final pointMap = <String, dynamic>{
        "Order": i,
        "Name": wayPoint.name,
        "Latitude": wayPoint.latitude,
        "Longitude": wayPoint.longitude,
      };
      pointList.add(pointMap);
    }
    var i = 0;
    var wayPointMap =
        Map.fromIterable(pointList, key: (e) => i++, value: (e) => e);

    var args = options.toMap();
    args["wayPoints"] = wayPointMap;
    if (args["mode"] == null) {
      args["mode"] = VTMapNavigationMode.driving;
    }

    await MapboxGlPlatform.getInstance(_id)!.startNavigation(args);
  }

  Future<void> clearRoute() async {
    return MapboxGlPlatform.getInstance(_id)!.clearRoute();
  }

  Future<void> selectedRoute(int routeSelectedIndex, EdgeInsets padding) async {
    return MapboxGlPlatform.getInstance(_id)!
        .selectedRoute(routeSelectedIndex, padding);
  }

  Future<void> setStyle(String styleString) async {
    return MapboxGlPlatform.getInstance(_id)!.setStyle(styleString);
  }

  Future<void> showOrHideLayer(String layerId, bool isShow) async {
    return MapboxGlPlatform.getInstance(_id)!.showOrHideLayer(layerId, isShow);
  }

  Future<void> addCustomLayer(
      {required String layerId,
      required LayerType layerType,
      required String sourceUrl,
      String? layerAbove,
      String? layerBelow,
      LayerOptions? options}) async {
    return MapboxGlPlatform.getInstance(_id)!.addCustomLayer(
        layerId, layerType, sourceUrl, layerAbove, layerBelow, options);
  }

//   Stream<RouteEvent> get _streamRouteEvent {
//     if (_onRouteEvent == null) {
//       _onRouteEvent = _eventChannel
//           .receiveBroadcastStream()
//           .map((dynamic event) => _parseRouteEvent(event));
//     }
//     return _onRouteEvent;
//   }

//  void _onProgressData(RouteEvent event) {
//     if (_routeEventNotifier != null) _routeEventNotifier(event);

//     if (event.eventType == MapBoxEvent.on_arrival)
//       _routeEventSubscription.cancel();
//   }

//    RouteEvent _parseRouteEvent(String jsonString) {
//     RouteEvent event;
//     var map = json.decode(jsonString);
//     var progressEvent = RouteProgressEvent.fromJson(map);
//     if (progressEvent != null && progressEvent.isProgressEvent) {
//       event = RouteEvent(
//           eventType: MapBoxEvent.progress_change, data: progressEvent);
//     } else
//       event = RouteEvent.fromJson(map);
//     return event;
//   }
}
