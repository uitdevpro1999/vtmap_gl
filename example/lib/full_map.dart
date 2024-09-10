import 'dart:async';
import 'dart:ffi';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:vtmap_gl/vtmap_gl.dart';
import 'main.dart';
import 'page.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'dart:convert';

class FullMapPage extends ExamplePage {
  FullMapPage() : super(const Icon(Icons.map), 'Full screen map');

  @override
  Widget build(BuildContext context) {
    return const FullMap();
  }
}

class FullMap extends StatefulWidget {
  const FullMap();

  @override
  State createState() => FullMapState();
}

class FullMapState extends State<FullMap> {
  late MapboxMapController mapController;
  bool setStyle = false;

  void _onMapCreated(MapboxMapController controller) {
    mapController = controller;
  }

  void _onCameraMovingStarted() {
    //print('------------------- _onCameraMovingStarted');
  }
  void _onCameraIdle() {
    // print('------------------- _onCameraIdle');
    // print(mapController.cameraPosition.target.latitude);
    // print(mapController.cameraPosition.target.longitude);
  }

  void _onStyleLoadedCallback() {
    mapController.showOrHideLayer("tbl_poi_google", true);
    var wayPoints = <WayPoint>[];
    final _origin =
        WayPoint(name: "origin", latitude: 16.060476, longitude: 108.215501);
    // WayPoint(name: "origin", latitude: 22.35442, longitude: 105.02262);

    // final _stop2 = WayPoint(
    //     name: "wp2", latitude:  16.064367555809767, longitude: 108.21520834606599);

    // final _stop3 = WayPoint(
    // name: "Way Point 23", latitude: 16.060947115368748, longitude: 108.21963504690751);

    final _stop1 =
        WayPoint(name: "dest", latitude: 16.066665, longitude: 108.210938);
    // WayPoint(name: "dest", latitude: 10.22503, longitude: 105.87859);

    wayPoints.add(_origin);
    //  wayPoints.add(_stop2);
    //   wayPoints.add(_stop3);
    wayPoints.add(_stop1);

    VTMapOptions option = VTMapOptions(
        alternatives: true, padding: EdgeInsets.only(top: 10, bottom: 300));

    mapController.buildRoute(wayPoints: wayPoints, options: option);
    print("--------------------------");
    print(setStyle);
    if (!setStyle) {
      //setStyle = true;
      //mapController.setStyle(
      //    'https://api.viettelmaps.vn/gateway/mapservice/v1/media/gtrans_style.json');
    }
    //mapController.onRouteSelected.add(_onRouteSelected);

    new Timer(const Duration(seconds: 6), () {
      ///print("This line will print after 8 seconds");
      //mapController.clearRoute();
      //mapController.buildRoute(wayPoints: wayPoints);

      // mapController.startNavigation(
      //     wayPoints: wayPoints,
      //     options: VTMapOptions(
      //         mode: VTMapNavigationMode.driving,
      //         simulateRoute: true,
      //         alternatives: true,
      //         startIndex: 0));

      //    if (!setStyle) {
      // setStyle = true;
      //   mapController.setStyle(
      //   'https://api.viettelmaps.vn/gateway/mapservice/v1/media/style-admin.json');
      //    }
      //mapController.selectedRoute(0, EdgeInsets.only(bottom: 1300, top: 10));

      //    if (!setStyle) {
      // setStyle = true;
      //   mapController.setStyle(
      //   'https://api.viettelmaps.vn/gateway/mapservice/v1/media/style-admin.json');
      //    }

      //mapController.selectedRoute(0, EdgeInsets.only(bottom: 600, top: 10));
    });

    new Timer(const Duration(seconds: 12), () {
      //print("-------------------------- invalidateAmbientCache");
      //mapController.invalidateAmbientCache();
      ///print("This line will print after 8 seconds");
      //mapController.clearRoute();
      //mapController.buildRoute(wayPoints: wayPoints);

      // mapController.startNavigation(
      //     wayPoints: wayPoints,
      //     options: VTMapOptions(
      //         mode: VTMapNavigationMode.driving,
      //         simulateRoute: true,
      //         alternatives: true,
      //         startIndex: 1));
      //    if (!setStyle) {
      // setStyle = true;
      //   mapController.setStyle(
      //   'https://api.viettelmaps.vn/gateway/mapservice/v1/media/style-admin.json');
      //    }
      //mapController.selectedRoute(0, EdgeInsets.only(top: 10, bottom: 300));
    });

    addSymbolLayer();
  }

  void addSymbolLayer() async {
    String layerId = 'covidLayer';
    String url = 'https://files-maps.atviettelsolutions.com/feature-point.json';
    mapController.addCustomLayer(
        layerId: layerId,
        layerType: LayerType.symbol,
        sourceUrl: url,
        options: LayerOptions(
            iconImage: 'restaurant', symbolIconAllowOverlap: true));
    // mapController.addCustomLayer(
    //     layerId: 'covidLayer10',
    //     layerType: LayerType.fill,
    //     sourceUrl: url,
    //     options: LayerOptions(
    //         fillColor: "blue", fillOutLineColor: "red", fillOpacity: 0.5));
    // new Timer(const Duration(seconds: 5), () {
    //   String url1 =
    //       'https://api-maps.atviettelsolutions.com/gateway/pois/v1/medical/source-polygon?name=HAC_79&layerCode=HAC_79';
    //   mapController.addCustomLayer(
    //       layerId: 'covidLayer1',
    //       layerType: LayerType.fill,
    //       sourceUrl: url1,
    //       options: LayerOptions(
    //           fillColor: "blue", fillOutLineColor: "red", fillOpacity: 0.5));

    //   url1 =
    //       'https://api-maps.atviettelsolutions.com/gateway/pois/v1/medical/source-polygon?name=HAC_01&layerCode=HAC_01';
    //   mapController.addCustomLayer(
    //       layerId: 'covidLayer2',
    //       layerType: LayerType.fill,
    //       sourceUrl: url1,
    //       options: LayerOptions(
    //           fillColor: "#FF00AA", fillOutLineColor: "red", fillOpacity: 0.5));
    // });

    // new Timer(const Duration(seconds: 10), () {
    //   mapController.showOrHideLayer(layerId, false);

    //   new Timer(const Duration(seconds: 3), () {
    //     mapController.showOrHideLayer(layerId, true);
    //   });
    // });
  }

  void _onRouteSelected(int index) {
    print("_onRouteSelected at : " + index.toString());
    Fluttertoast.showToast(
        msg: "_onRouteSelected at: " + index.toString(),
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0);
  }

  void getFeatureSelected(Point<double> point) async {
    var layerIds = ['tbl_provinces', 'tbl_districts'];
    List features = await (mapController.queryRenderedFeatures(
        point, layerIds, null) as FutureOr<List<dynamic>>);
    if (features.isNotEmpty) {
      Map<String, dynamic> feature = jsonDecode(features[0]);
      Fluttertoast.showToast(
          msg: "" +
              feature['properties']['name'].toString() +
              " : value is " +
              feature['properties']['perimeter'].toString(),
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        body: VTMap(
      accessToken: MapsDemo.ACCESS_TOKEN,
      // gpsControlEnable: true,
      // mapTypeControlEnable: true,
      // styleString:
      //   'https://api-maps.atviettelsolutions.com/gateway/mapservice/v1/media/style-covid.json',
      onMapCreated: _onMapCreated,
      onStyleLoadedCallback: _onStyleLoadedCallback,
      onCameraIdle: _onCameraIdle,
      gpsControlEnable: false,
      logoEnabled: false,

      minMaxZoomPreference: MinMaxZoomPreference(4, 20),
      //myLocationTrackingMode: MyLocationTrackingMode.TrackingCompass,
      onCameraMovingStarted: _onCameraMovingStarted,
      initialCameraPosition:
          const CameraPosition(target: LatLng(16.065423, 108.188714), zoom: 4),
      onMapClick: (Point<double>? point, LatLng? coordinates) {
        print("-------------------------- onMapClick: " + point.toString());
        getFeatureSelected(point!);
      },
    ));
  }
}
