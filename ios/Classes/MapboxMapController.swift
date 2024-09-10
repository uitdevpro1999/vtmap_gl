import Flutter
import UIKit
import Mapbox
import MapboxAnnotationExtension
import MapboxGeocoder
import MapboxDirections
import MapboxCoreNavigation
import MapboxNavigation
import Turf

class MapboxMapController: NSObject, FlutterPlatformView, MGLMapViewDelegate, MapboxMapOptionsSink, MGLAnnotationControllerDelegate,VMSGPSNewDelegate,VTMMapStyleDelegate,NavigationViewControllerDelegate {
    
    private var registrar: FlutterPluginRegistrar
    private var channel: FlutterMethodChannel?
    
    private var mapView: MGLMapView
    private var isMapReady = false
    private var mapReadyResult: FlutterResult?
    
    private var initialTilt: CGFloat?
    private var cameraTargetBounds: MGLCoordinateBounds?
    private var trackCameraPosition = false
    private var myLocationEnabled = false
    private var gpsControlEnabled = false;
    private var mapTypeControlEnabled = false;
    
    private var symbolAnnotationController: MGLSymbolAnnotationController?
    private var circleAnnotationController: MGLCircleAnnotationController?
    private var lineAnnotationController: MGLLineAnnotationController?
    private var fillAnnotationController: MGLPolygonAnnotationController?

    let sourceIdentifier = "routeSource"
    let sourceCasingIdentifier = "routeCasingSource"
    let routeLayerIdentifier = "routeLayer"
    let routeLayerCasingIdentifier = "routeLayerCasing"
    
    var defaultRouteCasing: UIColor { get { return #colorLiteral(red: 0.1843137255, green: 0.4784313725, blue: 0.7764705882, alpha: 1) } }
    var defaultRouteLayer: UIColor { get { return #colorLiteral(red: 0.337254902, green: 0.6588235294, blue: 0.9843137255, alpha: 1) } }
    var defaultAlternateLine: UIColor { get { return #colorLiteral(red: 0.6, green: 0.6, blue: 0.6, alpha: 1) } }
    var defaultAlternateLineCasing: UIColor { get { return #colorLiteral(red: 0.5019607843, green: 0.4980392157, blue: 0.5019607843, alpha: 1) } }
    var gpsControl : VTMGPSControl?
    var mapTypeControl : VTMMapTypeControl?

    var _navigationViewController : NavigationViewController?
    var directions: NavigationDirections
    private var originRoutes: [Route]?
    public var tapGestureDistanceThreshold: CGFloat = 50
    var padding = "50,50,50,50"
    
    func view() -> UIView {
        return mapView
    }
    
    init(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?, registrar: FlutterPluginRegistrar) {
        if let args = args as? [String: Any] {
            if let token = args["accessToken"] as? NSString{
                MGLAccountManager.accessToken = token
            } 
        }

        let defaultAccessToken = Bundle.main.object(forInfoDictionaryKey: "VTMapAccessToken") as? String
        directions  = NavigationDirections(accessToken: defaultAccessToken)
        mapView = MGLMapView(frame: frame)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.registrar = registrar 
        super.init()
        
        channel = FlutterMethodChannel(name: "plugins.flutter.io/mapbox_maps_\(viewId)", binaryMessenger: registrar.messenger())
        channel!.setMethodCallHandler{ [weak self] in self?.onMethodCall(methodCall: $0, result: $1) }
        
        mapView.delegate = self
          
        if let args = args as? [String: Any] {
             if let GPSControlEnable = args["GPSControlEnable"] as? Bool{
                gpsControl = VTMGPSControl.init(map: mapView, delegate: self)

               self.gpsControlEnabled = true
            }

             if let MapTypeControlEnable = args["MapTypeControlEnable"] as? Bool{
               mapTypeControl = VTMMapTypeControl.init(map: mapView, delegate: self)
               self.mapTypeControlEnabled = true
             }
           
         }
       

        
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(sender:)))
        for recognizer in mapView.gestureRecognizers! where recognizer is UITapGestureRecognizer {
            singleTap.require(toFail: recognizer)
        }
        mapView.addGestureRecognizer(singleTap)
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleMapLongPress(sender:)))
        for recognizer in mapView.gestureRecognizers! where recognizer is UILongPressGestureRecognizer {
            longPress.require(toFail: recognizer)
        }
        mapView.addGestureRecognizer(longPress)

        if let args = args as? [String: Any] {
            Convert.interpretMapboxMapOptions(options: args["options"], delegate: self)
            if let initialCameraPosition = args["initialCameraPosition"] as? [String: Any],
                let camera = MGLMapCamera.fromDict(initialCameraPosition, mapView: mapView),
                let zoom = initialCameraPosition["zoom"] as? Double {
                mapView.setCenter(camera.centerCoordinate, zoomLevel: zoom, direction: camera.heading, animated: false)
                initialTilt = camera.pitch
            }
        }
    } 



    func onMethodCall(methodCall: FlutterMethodCall, result: @escaping FlutterResult) {
        switch(methodCall.method) {
        case "map#waitForMap":
            if isMapReady {
                result(nil)
            } else {
                mapReadyResult = result
            }
        case "map#update":
            guard let arguments = methodCall.arguments as? [String: Any] else { return }
            Convert.interpretMapboxMapOptions(options: arguments["options"], delegate: self)
            if let camera = getCamera() {
                result(camera.toDict(mapView: mapView))
            } else {
                result(nil)
            }
        case "map#invalidateAmbientCache":
            MGLOfflineStorage.shared.invalidateAmbientCache{
                (error) in
                if let error = error {
                    result(error)
                } else{
                    result(nil)
                }
            }
        case "map#updateMyLocationTrackingMode":
            guard let arguments = methodCall.arguments as? [String: Any] else { return }
            if let myLocationTrackingMode = arguments["mode"] as? UInt, let trackingMode = MGLUserTrackingMode(rawValue: myLocationTrackingMode) {
                setMyLocationTrackingMode(myLocationTrackingMode: trackingMode)
            }
            result(nil)
        case "map#matchMapLanguageWithDeviceDefault":
            if let style = mapView.style {
                style.localizeLabels(into: nil)
            }
            result(nil)
        case "map#updateContentInsets":
            guard let arguments = methodCall.arguments as? [String: Any] else { return }

            if let bounds = arguments["bounds"] as? [String: Any],
                let top = bounds["top"] as? CGFloat,
                let left = bounds["left"]  as? CGFloat,
                let bottom = bounds["bottom"] as? CGFloat,
                let right = bounds["right"] as? CGFloat,
                let animated = arguments["animated"] as? Bool {
                mapView.setContentInset(UIEdgeInsets(top: top, left: left, bottom: bottom, right: right), animated: animated) {
                    result(nil)
                }
            } else {
                result(nil)
            }
        case "map#setMapLanguage":
            guard let arguments = methodCall.arguments as? [String: Any] else { return }
            if let localIdentifier = arguments["language"] as? String, let style = mapView.style {
                let locale = Locale(identifier: localIdentifier)
                style.localizeLabels(into: locale)
            }
            result(nil)
        case "map#queryRenderedFeatures":
            guard let arguments = methodCall.arguments as? [String: Any] else { return }
            let layerIds1 = arguments["layerIds"] as? [String]
            var layerIds: Set<String> = Set([])
            
            if (layerIds1 != nil){
                layerIds = Set(layerIds1!)
            }
            
            var filterExpression: NSPredicate?
            if let filter = arguments["filter"] as? [Any] {
                filterExpression = NSPredicate(mglJSONObject: filter)
            }
            var reply = [String: NSObject]()
            var features:[MGLFeature] = []
            if let x = arguments["x"] as? Double, let y = arguments["y"] as? Double {
                features = mapView.visibleFeatures(at: CGPoint(x: x, y: y), styleLayerIdentifiers: layerIds, predicate: filterExpression)
            }
            if  let top = arguments["top"] as? Double,
                let bottom = arguments["bottom"] as? Double,
                let left = arguments["left"] as? Double,
                let right = arguments["right"] as? Double {
                features = mapView.visibleFeatures(in: CGRect(x: left, y: top, width: right, height: bottom), styleLayerIdentifiers: layerIds, predicate: filterExpression)
            }
            var featuresJson = [String]()
            for feature in features {
                let dictionary = feature.geoJSONDictionary()
                if  let theJSONData = try? JSONSerialization.data(withJSONObject: dictionary, options: []),
                    let theJSONText = String(data: theJSONData, encoding: .ascii) {
                    featuresJson.append(theJSONText)
                }
            }
            reply["features"] = featuresJson as NSObject
            result(reply)
        case "map#setTelemetryEnabled":
            guard let arguments = methodCall.arguments as? [String: Any] else { return }
            let telemetryEnabled = arguments["enabled"] as? Bool
            UserDefaults.standard.set(telemetryEnabled, forKey: "MGLMapboxMetricsEnabled")
            result(nil)
        case "map#getTelemetryEnabled":
            let telemetryEnabled = UserDefaults.standard.bool(forKey: "MGLMapboxMetricsEnabled")
            result(telemetryEnabled)
        case "map#getVisibleRegion":
            var reply = [String: NSObject]()
            let visibleRegion = mapView.visibleCoordinateBounds
            reply["sw"] = [visibleRegion.sw.latitude, visibleRegion.sw.longitude] as NSObject
            reply["ne"] = [visibleRegion.ne.latitude, visibleRegion.ne.longitude] as NSObject
            result(reply)
        case "map#toScreenLocation":
            guard let arguments = methodCall.arguments as? [String: Any] else { return }
            guard let latitude = arguments["latitude"] as? Double else { return }
            guard let longitude = arguments["longitude"] as? Double else { return }
            let latlng = CLLocationCoordinate2DMake(latitude, longitude)
            let returnVal = mapView.convert(latlng, toPointTo: mapView)
            var reply = [String: NSObject]()
            reply["x"] = returnVal.x as NSObject
            reply["y"] = returnVal.y as NSObject
            result(reply)
        case "map#getMetersPerPixelAtLatitude":
             guard let arguments = methodCall.arguments as? [String: Any] else { return }
             var reply = [String: NSObject]()
             guard let latitude = arguments["latitude"] as? Double else { return }
             let returnVal = mapView.metersPerPoint(atLatitude:latitude)
             reply["metersperpixel"] = returnVal as NSObject
             result(reply)
        case "map#toLatLng":
            guard let arguments = methodCall.arguments as? [String: Any] else { return }
            guard let x = arguments["x"] as? Double else { return }
            guard let y = arguments["y"] as? Double else { return }
            let screenPoint: CGPoint = CGPoint(x: y, y:y)
            let coordinates: CLLocationCoordinate2D = mapView.convert(screenPoint, toCoordinateFrom: mapView)
            var reply = [String: NSObject]()
            reply["latitude"] = coordinates.latitude as NSObject
            reply["longitude"] = coordinates.longitude as NSObject
            result(reply)
        case "map#setStyle":
            guard let arguments = methodCall.arguments as? [String: Any] else { return }
            guard let styleString = arguments["styleString"] as? String else { return }
            setStyleString(styleString:styleString)
        case "map#clearRoute":
           removeRoutes()
           result(nil)        
        case "map#buildRoute":
            guard let arguments = methodCall.arguments as? NSDictionary else { return }
            buildRoute(arguments: arguments, flutterResult: result)
            result(nil)
        case "map#selectedRoute":
            guard let arguments = methodCall.arguments as? [String: Any] else { return }
            guard let index = arguments["routeSelectedIndex"] as? Int else { return }
            
            self.padding = arguments["padding"] as? String ?? self.padding
            guard let selectedRoute = self.originRoutes?[index] else {return}
            self.showRouteWithIndex(index: index, selectedRoute: selectedRoute)
            
            result(nil)
            
        case "map#showOrHideLayer":
            guard let arguments = methodCall.arguments as? [String: Any] else { return }
            guard let layerId = arguments["layerId"] as? String else { return }
            guard let isShow = arguments["isShow"] as? Bool else { return }
            
            guard let style = mapView.style else { return }
            if let layer = style.layer(withIdentifier: layerId){
                layer.isVisible = isShow
            }
            
            result(nil)

        case "map#startNavigation":
           guard let arguments = methodCall.arguments as? NSDictionary else { return }
            startNavigation(arguments: arguments, flutterResult: result)
        case "camera#move":
            guard let arguments = methodCall.arguments as? [String: Any] else { return }
            guard let cameraUpdate = arguments["cameraUpdate"] as? [Any] else { return }
            if let camera = Convert.parseCameraUpdate(cameraUpdate: cameraUpdate, mapView: mapView) {
                mapView.setCamera(camera, animated: false)
            }
            result(nil)
        case "camera#animate":
            guard let arguments = methodCall.arguments as? [String: Any] else { return }
            guard let cameraUpdate = arguments["cameraUpdate"] as? [Any] else { return }
            if let camera = Convert.parseCameraUpdate(cameraUpdate: cameraUpdate, mapView: mapView) {
                if let duration = arguments["duration"] as? TimeInterval {
                    mapView.setCamera(camera, withDuration: TimeInterval(duration / 1000), 
                        animationTimingFunction: CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut))
                    result(nil)
                }
                mapView.setCamera(camera, animated: true)
            }
            result(nil)
        case "symbols#addAll":
            guard let symbolAnnotationController = symbolAnnotationController else { return }
            guard let arguments = methodCall.arguments as? [String: Any] else { return }

            if let options = arguments["options"] as? [[String: Any]] {
                var symbols: [MGLSymbolStyleAnnotation] = [];
                for o in options {
                    if let symbol = getSymbolForOptions(options: o)  {
                        symbols.append(symbol)
                    }
                }
                if !symbols.isEmpty {
                    symbolAnnotationController.addStyleAnnotations(symbols)
                }

                result(symbols.map { $0.identifier })
            } else {
                result(nil)
            }
        case "symbol#update":
            guard let symbolAnnotationController = symbolAnnotationController else { return }
            guard let arguments = methodCall.arguments as? [String: Any] else { return }
            guard let symbolId = arguments["symbol"] as? String else { return }

            for symbol in symbolAnnotationController.styleAnnotations(){
                if symbol.identifier == symbolId {
                    Convert.interpretSymbolOptions(options: arguments["options"], delegate: symbol as! MGLSymbolStyleAnnotation)
                    // Load (updated) icon image from asset if an icon name is supplied.
                    if let options = arguments["options"] as? [String: Any],
                        let iconImage = options["iconImage"] as? String {
                        addIconImageToMap(iconImageName: iconImage)
                    }
                    symbolAnnotationController.updateStyleAnnotation(symbol)
                    break;
                }
            }
            result(nil)
        case "symbols#removeAll":
            guard let symbolAnnotationController = symbolAnnotationController else { return }
            guard let arguments = methodCall.arguments as? [String: Any] else { return }
            guard let symbolIds = arguments["symbols"] as? [String] else { return }
            var symbols: [MGLSymbolStyleAnnotation] = [];

            for symbol in symbolAnnotationController.styleAnnotations(){
                if symbolIds.contains(symbol.identifier) {
                    symbols.append(symbol as! MGLSymbolStyleAnnotation)
                }
            }
            symbolAnnotationController.removeStyleAnnotations(symbols)
            result(nil)
        case "symbol#getGeometry":
            guard let symbolAnnotationController = symbolAnnotationController else { return }
            guard let arguments = methodCall.arguments as? [String: Any] else { return }
            guard let symbolId = arguments["symbol"] as? String else { return }

            var reply: [String:Double]? = nil
            for symbol in symbolAnnotationController.styleAnnotations(){
                if symbol.identifier == symbolId {
                    if let geometry = symbol.geoJSONDictionary["geometry"] as? [String: Any],
                        let coordinates = geometry["coordinates"] as? [Double] {
                        reply = ["latitude": coordinates[1], "longitude": coordinates[0]]
                    }
                    break;
                }
            }
            result(reply)
        case "symbolManager#iconAllowOverlap":
            guard let symbolAnnotationController = symbolAnnotationController else { return }
            guard let arguments = methodCall.arguments as? [String: Any] else { return }
            guard let iconAllowOverlap = arguments["iconAllowOverlap"] as? Bool else { return }

            symbolAnnotationController.iconAllowsOverlap = iconAllowOverlap
            result(nil)
        case "symbolManager#iconIgnorePlacement":
            guard let symbolAnnotationController = symbolAnnotationController else { return }
            guard let arguments = methodCall.arguments as? [String: Any] else { return }
            guard let iconIgnorePlacement = arguments["iconIgnorePlacement"] as? Bool else { return }

            symbolAnnotationController.iconIgnoresPlacement = iconIgnorePlacement
            result(nil)
        case "symbolManager#textAllowOverlap":
            guard let symbolAnnotationController = symbolAnnotationController else { return }
            guard let arguments = methodCall.arguments as? [String: Any] else { return }
            guard let textAllowOverlap = arguments["textAllowOverlap"] as? Bool else { return }

            symbolAnnotationController.textAllowsOverlap = textAllowOverlap
            result(nil)
        case "symbolManager#textIgnorePlacement":
            result(FlutterMethodNotImplemented)
        case "circle#add":
            guard let circleAnnotationController = circleAnnotationController else { return }
            guard let arguments = methodCall.arguments as? [String: Any] else { return }
            // Parse geometry
            if let options = arguments["options"] as? [String: Any],
                let geometry = options["geometry"] as? [Double] {
                // Convert geometry to coordinate and create circle.
                let coordinate = CLLocationCoordinate2DMake(geometry[0], geometry[1])
                let circle = MGLCircleStyleAnnotation(center: coordinate)
                Convert.interpretCircleOptions(options: arguments["options"], delegate: circle)
                circleAnnotationController.addStyleAnnotation(circle)
                result(circle.identifier)
            } else {
                result(nil)
            }
        case "circle#update":
            guard let circleAnnotationController = circleAnnotationController else { return }  
            guard let arguments = methodCall.arguments as? [String: Any] else { return }
            guard let circleId = arguments["circle"] as? String else { return }
            
            for circle in circleAnnotationController.styleAnnotations() {
                if circle.identifier == circleId {
                    Convert.interpretCircleOptions(options: arguments["options"], delegate: circle as! MGLCircleStyleAnnotation)
                    circleAnnotationController.updateStyleAnnotation(circle)
                    break;
                }
            }
            result(nil)
        case "circle#remove":
            guard let circleAnnotationController = circleAnnotationController else { return }
            guard let arguments = methodCall.arguments as? [String: Any] else { return }
            guard let circleId = arguments["circle"] as? String else { return }
            
            for circle in circleAnnotationController.styleAnnotations() {
                if circle.identifier == circleId {
                    circleAnnotationController.removeStyleAnnotation(circle)
                    break;
                }
            }
            result(nil)
        case "line#add":
            guard let lineAnnotationController = lineAnnotationController else { return }
            guard let arguments = methodCall.arguments as? [String: Any] else { return }
            // Parse geometry
            if let options = arguments["options"] as? [String: Any],
                let geometry = options["geometry"] as? [[Double]] {
                // Convert geometry to coordinate and create a line.
                var lineCoordinates: [CLLocationCoordinate2D] = []
                for coordinate in geometry {
                    lineCoordinates.append(CLLocationCoordinate2DMake(coordinate[0], coordinate[1]))
                }
                let line = MGLLineStyleAnnotation(coordinates: lineCoordinates, count: UInt(lineCoordinates.count))
                Convert.interpretLineOptions(options: arguments["options"], delegate: line)
                lineAnnotationController.addStyleAnnotation(line)
                result(line.identifier)
            } else {
                result(nil)
            }
        case "line#update":
            guard let lineAnnotationController = lineAnnotationController else { return }
            guard let arguments = methodCall.arguments as? [String: Any] else { return }
            guard let lineId = arguments["line"] as? String else { return }
            
            for line in lineAnnotationController.styleAnnotations() {
                if line.identifier == lineId {
                    Convert.interpretLineOptions(options: arguments["options"], delegate: line as! MGLLineStyleAnnotation)
                    lineAnnotationController.updateStyleAnnotation(line)
                    break;
                }
            }
            result(nil)
        case "line#remove":
            guard let lineAnnotationController = lineAnnotationController else { return }
            guard let arguments = methodCall.arguments as? [String: Any] else { return }
            guard let lineId = arguments["line"] as? String else { return }
            
            for line in lineAnnotationController.styleAnnotations() {
                if line.identifier == lineId {
                    lineAnnotationController.removeStyleAnnotation(line)
                    break;
                }
            }
            result(nil)
        case "line#getGeometry":
            guard let lineAnnotationController = lineAnnotationController else { return }
            guard let arguments = methodCall.arguments as? [String: Any] else { return }
            guard let lineId = arguments["line"] as? String else { return }

            var reply: [Any]? = nil
            for line in lineAnnotationController.styleAnnotations() {
                if line.identifier == lineId {
                    if let geometry = line.geoJSONDictionary["geometry"] as? [String: Any],
                        let coordinates = geometry["coordinates"] as? [[Double]] {
                        reply = coordinates.map { [ "latitude": $0[1], "longitude": $0[0] ] }
                    }
                    break;
                }
            }
            result(reply)
        case "fill#add":
            guard let fillAnnotationController = fillAnnotationController else { return }
            guard let arguments = methodCall.arguments as? [String: Any] else { return }
            // Parse geometry
            var identifier: String? = nil
            if let options = arguments["options"] as? [String: Any],
                let geometry = options["geometry"] as? [[[Double]]] {
                guard geometry.count > 0 else { break }
                // Convert geometry to coordinate and interior polygonc.
                var fillCoordinates: [CLLocationCoordinate2D] = []
                for coordinate in geometry[0] {
                    fillCoordinates.append(CLLocationCoordinate2DMake(coordinate[0], coordinate[1]))
                }
                let polygons = Convert.toPolygons(geometry: geometry.tail)
                let fill = MGLPolygonStyleAnnotation(coordinates: fillCoordinates, count: UInt(fillCoordinates.count), interiorPolygons: polygons)
                Convert.interpretFillOptions(options: arguments["options"], delegate: fill)
                fillAnnotationController.addStyleAnnotation(fill)
                identifier = fill.identifier
            }
            result(identifier)
        case "fill#update":
            guard let fillAnnotationController = fillAnnotationController else { return }
            guard let arguments = methodCall.arguments as? [String: Any] else { return }
            guard let fillId = arguments["fill"] as? String else { return }
        
            for fill in fillAnnotationController.styleAnnotations() {
                if fill.identifier == fillId {
                    Convert.interpretFillOptions(options: arguments["options"], delegate: fill as! MGLPolygonStyleAnnotation)
                    fillAnnotationController.updateStyleAnnotation(fill)
                    break;
                }
            }
            result(nil)
        case "fill#remove":
            guard let fillAnnotationController = fillAnnotationController else { return }
            guard let arguments = methodCall.arguments as? [String: Any] else { return }
            guard let fillId = arguments["fill"] as? String else { return }
        
            for fill in fillAnnotationController.styleAnnotations() {
                if fill.identifier == fillId {
                    fillAnnotationController.removeStyleAnnotation(fill)
                    break;
                }
            }
            result(nil)
        case "style#addImage":
            guard let arguments = methodCall.arguments as? [String: Any] else { return }
            guard let name = arguments["name"] as? String else { return }
            //guard let length = arguments["length"] as? NSNumber else { return }
            guard let bytes = arguments["bytes"] as? FlutterStandardTypedData else { return }
            guard let sdf = arguments["sdf"] as? Bool else { return }
            guard let data = bytes.data as? Data else{ return }
            guard let image = UIImage(data: data) else { return }
            if (sdf) {
                self.mapView.style?.setImage(image.withRenderingMode(.alwaysTemplate), forName: name)
            } else {
                self.mapView.style?.setImage(image, forName: name)
            }
            result(nil)
        case "style#addImageSource":
            guard let arguments = methodCall.arguments as? [String: Any] else { return }
            guard let name = arguments["name"] as? String else { return }
            guard let bytes = arguments["bytes"] as? FlutterStandardTypedData else { return }
            guard let data = bytes.data as? Data else { return }
            guard let image = UIImage(data: data) else { return }
            
            guard let coordinates = arguments["coordinates"] as? [[Double]] else { return };
            let quad = MGLCoordinateQuad(
                topLeft: CLLocationCoordinate2D(latitude: coordinates[0][0], longitude: coordinates[0][1]),
                bottomLeft: CLLocationCoordinate2D(latitude: coordinates[3][0], longitude: coordinates[3][1]),
                bottomRight: CLLocationCoordinate2D(latitude: coordinates[2][0], longitude: coordinates[2][1]),
                topRight: CLLocationCoordinate2D(latitude: coordinates[1][0], longitude: coordinates[1][1])
            )
            
            let source = MGLImageSource(identifier: name, coordinateQuad: quad, image: image)
            self.mapView.style?.addSource(source)
            
            result(nil)
        case "style#removeImageSource":
            guard let arguments = methodCall.arguments as? [String: Any] else { return }
            guard let name = arguments["name"] as? String else { return }
            guard let source = self.mapView.style?.source(withIdentifier: name) else { return }
            self.mapView.style?.removeSource(source)
            result(nil)
        case "style#addLayer":
            guard let arguments = methodCall.arguments as? [String: Any] else { return }
            guard let name = arguments["name"] as? String else { return }
            guard let sourceId = arguments["sourceId"] as? String else { return }
            
            guard let source = self.mapView.style?.source(withIdentifier: sourceId) else { return }
            let layer = MGLRasterStyleLayer(identifier: name, source: source)
            self.mapView.style?.addLayer(layer)
            result(nil)
        case "style#removeLayer":
            guard let arguments = methodCall.arguments as? [String: Any] else { return }
            guard let name = arguments["name"] as? String else { return }
            guard let layer = self.mapView.style?.layer(withIdentifier: name) else { return }
            self.mapView.style?.removeLayer(layer)
            result(nil)
        case "style#addSymbolLayer":
            
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    
    private func buildRoute(arguments: NSDictionary?, flutterResult: @escaping FlutterResult){
      
        var _allowsUTurnAtWayPoints: Bool?
        let _language = "vi"
        let _voiceUnits = "imperial"
        var _navigationMode: String?
        var _includesAlternativeRoutes = false
        _includesAlternativeRoutes = arguments?["alternatives"] as? Bool ?? _includesAlternativeRoutes
        
        self.padding = arguments?["padding"] as? String ?? self.padding
        guard let oWayPoints = arguments?["wayPoints"] as? NSDictionary else {return}
        if(oWayPoints.count < 2){
            return
        }
         var _wayPoints = [Waypoint]()
        
         for item in oWayPoints as NSDictionary
            {
                let originPoint = item.value as! NSDictionary
                guard let originPointName = originPoint["Name"] as? String else {return}
                guard let originPointLatitude = originPoint["Latitude"] as? Double else {return}
                guard let originPointLongitude = originPoint["Longitude"] as? Double else {return}
                let wayPoint = Waypoint(coordinate: CLLocationCoordinate2D(latitude: originPointLatitude, longitude: originPointLongitude),
                                            coordinateAccuracy: -1, name: originPointName)

                _wayPoints.append(wayPoint)
            }
                
        
                if(_wayPoints.count > 3 && arguments?["mode"] == nil)
                {
                    _navigationMode = "driving"
                }
                
                var mode: MBDirectionsProfileIdentifier = .automobile
                
                if (_navigationMode == "cycling")
                {
                    mode = .cycling
                }
                else if(_navigationMode == "driving")
                {
                    mode = .automobile
                }
                else
                {
                    mode = .automobile
                }
                
                let routeOptions = NavigationRouteOptions(waypoints: _wayPoints, profileIdentifier: mode)
                
                if (_allowsUTurnAtWayPoints != nil)
                {
                    routeOptions.allowsUTurnAtWaypoint = _allowsUTurnAtWayPoints!
                }
                
                routeOptions.distanceMeasurementSystem = _voiceUnits == "imperial" ? .imperial : .metric
                routeOptions.locale = Locale(identifier: _language)
                routeOptions.includesSteps = true
                routeOptions.includesAlternativeRoutes = _includesAlternativeRoutes

                // Generate the route object and draw it on the map
                 Directions.shared.calculate(routeOptions) { [weak self] (aypoints, routes, error)in
                     if let strongSelf = self {
                   guard let routes = routes else { return }
                    //strongSelf.sendEvent(eventType: MapBoxEventType.route_built)
                        
                       if let route = routes.first{
                        strongSelf.originRoutes = routes
                            if route.coordinateCount > 0 {
                                strongSelf.showRoute(routes: routes,padding: strongSelf.padding)
                            }
                        }
                        
                    flutterResult(true)
                }
        }
        
    }

    func startNavigation(arguments: NSDictionary?, flutterResult: @escaping FlutterResult){
               
               var _allowsUTurnAtWayPoints: Bool?
               var _isOptimized = false
               var _language = "vi"
               var _navigationMode: String?
               var _includesAlternativeRoutes = false
               var _simulateRoute = false
               var _indexOfRoute = 0
                _language = arguments?["language"] as? String ?? _language
                _simulateRoute = arguments?["simulateRoute"] as? Bool ?? _simulateRoute
                _isOptimized = arguments?["isOptimized"] as? Bool ?? _isOptimized
                _allowsUTurnAtWayPoints = arguments?["allowsUTurnAtWayPoints"] as? Bool
                _navigationMode = arguments?["mode"] as? String ?? "driving"
                _includesAlternativeRoutes = arguments?["alternatives"] as? Bool ?? _includesAlternativeRoutes
                _indexOfRoute = arguments?["startIndex"] as? Int ?? _indexOfRoute
               guard let oWayPoints = arguments?["wayPoints"] as? NSDictionary else {return}
               if(oWayPoints.count < 2){
                   return
               }
                var _wayPoints = [Waypoint]()
               
                for item in oWayPoints as NSDictionary
                   {
                       let originPoint = item.value as! NSDictionary
                       guard let originPointName = originPoint["Name"] as? String else {return}
                       guard let originPointLatitude = originPoint["Latitude"] as? Double else {return}
                       guard let originPointLongitude = originPoint["Longitude"] as? Double else {return}
                       let wayPoint = Waypoint(coordinate: CLLocationCoordinate2D(latitude: originPointLatitude, longitude: originPointLongitude),
                                                   coordinateAccuracy: -1, name: originPointName)
                       _wayPoints.append(wayPoint)
                   }
                       
                       
                       var mode: MBDirectionsProfileIdentifier = .automobile
                       
                       if (_navigationMode == "cycling")
                       {
                           mode = .cycling
                       }
                       else if(_navigationMode == "driving")
                       {
                           mode = .automobile
                       }
                       else
                       {
                           mode = .automobile
                       }
                       
                       let routeOptions = NavigationRouteOptions(waypoints: _wayPoints, profileIdentifier: mode)
                       
                       if (_allowsUTurnAtWayPoints != nil)
                       {
                           routeOptions.allowsUTurnAtWaypoint = _allowsUTurnAtWayPoints!
                       }
                       
                       routeOptions.distanceMeasurementSystem = .metric
                       routeOptions.locale = Locale(identifier: _language)
                       routeOptions.includesSteps = true
                       routeOptions.includesAlternativeRoutes = _includesAlternativeRoutes

                       // Generate the route object and draw it on the map
                        Directions.shared.calculate(routeOptions) { [weak self] (aypoints, routes, error)in
                            if let strongSelf = self {
                          guard let routes = routes else { return }
                            if(_indexOfRoute < routes.count){
                                let route  = routes[_indexOfRoute]
                                if route.coordinateCount > 0 {
                                 strongSelf.startNavigationWithRoute(route: route,simulateRoute: _simulateRoute)
                                }
                           }
                                
                           flutterResult(true)
                       }
               }
    }
    
    func startNavigationWithRoute(route: Route,simulateRoute: Bool){
        if(self._navigationViewController == nil)
        {

            let navigationService = MapboxNavigationService(route: route, directions: self.directions, simulating: simulateRoute ? .always: .never)
            let navigationOptions = NavigationOptions(styles: [DayStyle()], navigationService: navigationService)

            self._navigationViewController =  NavigationViewController(for: route, options: navigationOptions)
            self._navigationViewController!.modalPresentationStyle = .fullScreen
            self._navigationViewController!.delegate = self
            self._navigationViewController!.mapView?.localizeLabels()
            self._navigationViewController!.mapView?.styleURL = MGLStyle.streetsStyleURL
        }
        
       let flutterViewController = UIApplication.shared.delegate?.window??.rootViewController as! FlutterViewController
       flutterViewController.present(self._navigationViewController!, animated: true, completion: nil)
        
    }
    
    func showRoute(routes: [Route],padding: String){
        guard let style = mapView.style else { return }
        removeRoutes()
        
        guard let firstRoute = routes.first else { return }
        
        var altRoutes: [MGLPolylineFeature] = []
        
        for route in routes.suffix(from: 1) {
            let polyline = MGLPolylineFeature(coordinates: route.coordinates!, count: UInt(route.coordinates!.count))
            polyline.attributes["isAlternateRoute"] = true
            altRoutes.append(polyline)
        }
        
        let lines = [MGLPolylineFeature(coordinates: firstRoute.coordinates!, count: UInt(firstRoute.coordinates!.count))]
        
        for line in lines {
            line.attributes["isAlternateRoute"] = false
        }
        
         let polylines = MGLShapeCollectionFeature(shapes: altRoutes + lines)
         let mainPolylineSimplified = MGLShapeCollectionFeature(shapes: lines)
         
         if let source = style.source(withIdentifier: sourceIdentifier) as? MGLShapeSource,
             let sourceSimplified = style.source(withIdentifier: sourceCasingIdentifier) as? MGLShapeSource {
             source.shape = polylines
             sourceSimplified.shape = mainPolylineSimplified
         } else {
             let lineSource = MGLShapeSource(identifier: self.sourceIdentifier, shape: polylines, options: [.lineDistanceMetrics: true])
             let lineCasingSource = MGLShapeSource(identifier: self.sourceCasingIdentifier, shape: mainPolylineSimplified, options: [.lineDistanceMetrics: true])
             style.addSource(lineSource)
             style.addSource(lineCasingSource)
             
            let line = routeStyleLayer(identifier: routeLayerIdentifier, source: lineSource)
            let lineCasing = routeCasingStyleLayer(identifier: routeLayerCasingIdentifier, source: lineSource)
             
             for layer in style.layers {
                if(layer.identifier.contains("annotations-extension-layer")){
                     style.insertLayer(line, below: layer)
                     style.insertLayer(lineCasing, below: line)
                     break
                }
             }
     }
        var routeCoordinates = firstRoute.coordinates!
        let paddings = padding.components(separatedBy: ",")
        mapView.setVisibleCoordinates(&routeCoordinates, count: firstRoute.coordinateCount, edgePadding: UIEdgeInsets.init(top: CGFloat((paddings[1] as NSString).floatValue) , left: CGFloat((paddings[0] as NSString).floatValue) , bottom: CGFloat((paddings[3] as NSString).floatValue) , right: CGFloat((paddings[2] as NSString).floatValue) ), animated: true)
    }
    
    func removeRoutes() {
           guard let style = mapView.style else {
               return
           }
           
           if let line = style.layer(withIdentifier: routeLayerIdentifier) {
               style.removeLayer(line)
           }
           
           if let lineCasing = style.layer(withIdentifier: routeLayerCasingIdentifier) {
               style.removeLayer(lineCasing)
           }
           
           if let lineSource = style.source(withIdentifier: sourceIdentifier) {
               style.removeSource(lineSource)
           }
           
           if let lineCasingSource = style.source(withIdentifier: sourceCasingIdentifier) {
               style.removeSource(lineCasingSource)
           }
       }
       
       func routeStyleLayer(identifier: String, source: MGLSource) -> MGLStyleLayer {
           
           let line = MGLLineStyleLayer(identifier: identifier, source: source)
           line.lineWidth = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)", MBRouteLineWidthByZoomLevel.multiplied(by: 0.6))
          line.lineOpacity =  NSExpression(forConstantValue: 1)
          //line.lineColor = NSExpression(forConstantValue: defaultRouteLayer)
          line.lineColor = NSExpression(forConditional: NSPredicate(format: "isAlternateRoute == true"),
                     trueExpression: NSExpression(forConstantValue: defaultAlternateLine),
                     falseExpression: NSExpression(forConstantValue: defaultRouteLayer))
           line.lineJoin = NSExpression(forConstantValue: "round")
           
           return line
       }
       
       func routeCasingStyleLayer(identifier: String, source: MGLSource) -> MGLStyleLayer {
           
           let lineCasing = MGLLineStyleLayer(identifier: identifier, source: source)
           
           // Take the default line width and make it wider for the casing
           lineCasing.lineWidth = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)", MBRouteLineWidthByZoomLevel.multiplied(by: 1.0))
           
           //lineCasing.lineColor =  NSExpression(forConstantValue: defaultRouteCasing)
           lineCasing.lineColor = NSExpression(forConditional: NSPredicate(format: "isAlternateRoute == true"),
                     trueExpression: NSExpression(forConstantValue: defaultAlternateLineCasing),
                     falseExpression: NSExpression(forConstantValue: defaultRouteCasing))

           lineCasing.lineCap = NSExpression(forConstantValue: "round")
           lineCasing.lineJoin = NSExpression(forConstantValue: "round")
           lineCasing.lineOpacity = NSExpression(forConstantValue: 1)
           
           return lineCasing
       }
        
    private func moveCameraToCenter()
       {
           let duration = 5.0
           // Create a camera that rotates around the same center point, rotating 180°.
           // `fromDistance:` is meters above mean sea level that an eye would have to be in order to see what the map view is showing.
           let camera = MGLMapCamera(lookingAtCenter: mapView.centerCoordinate, altitude: 2500, pitch: 15, heading: 180)
           
           // Animate the camera movement over 5 seconds.
           mapView.setCamera(camera, withDuration: duration, animationTimingFunction: CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut))
       }
    
    private func getSymbolForOptions(options: [String: Any]) -> MGLSymbolStyleAnnotation? {
        // Parse geometry
        if let geometry = options["geometry"] as? [Double] {
            // Convert geometry to coordinate and create symbol.
            let coordinate = CLLocationCoordinate2DMake(geometry[0], geometry[1])
            let symbol = MGLSymbolStyleAnnotation(coordinate: coordinate)
            Convert.interpretSymbolOptions(options: options, delegate: symbol)
            // Load icon image from asset if an icon name is supplied.
            if let iconImage = options["iconImage"] as? String {
                addIconImageToMap(iconImageName: iconImage)
            }
            return symbol
        }
        return nil
    }

    private func addIconImageToMap(iconImageName: String) {
        // Check if the image has already been added to the map.
        if self.mapView.style?.image(forName: iconImageName) == nil {
            // Build up the full path of the asset.
            // First find the last '/' ans split the image name in the asset directory and the image file name.
            if let range = iconImageName.range(of: "/", options: [.backwards]) {
                let directory = String(iconImageName[..<range.lowerBound])
                let assetPath = registrar.lookupKey(forAsset: "\(directory)/")
                let fileName = String(iconImageName[range.upperBound...])
                // If we can load the image from file then add it to the map.
                if let imageFromAsset = UIImage.loadFromFile(imagePath: assetPath, imageName: fileName) {
                    self.mapView.style?.setImage(imageFromAsset, forName: iconImageName)
                }
            }
        }
    }

    private func updateMyLocationEnabled() {
        mapView.showsUserLocation = self.myLocationEnabled
    }
    
    private func getCamera() -> MGLMapCamera? {
        return trackCameraPosition ? mapView.camera : nil
        
    }
    
    /*
    *  UITapGestureRecognizer
    *  On tap invoke the map#onMapClick callback.
    */
    @objc @IBAction func handleMapTap(sender: UITapGestureRecognizer) {
        // Get the CGPoint where the user tapped.
        let point = sender.location(in: mapView)
       
        let selectedRoutes = getSelectedRoute(closeTo: point)
        if let selectedRoute = selectedRoutes?.first{
            guard let index = self.originRoutes?.firstIndex(of: selectedRoute) else {return}
            showRouteWithIndex(index: index,selectedRoute: selectedRoute)
            channel?.invokeMethod("map#onRouteSelected", arguments: ["routeIndex": index])
        }else{
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
            channel?.invokeMethod("map#onMapClick", arguments: [
                         "x": point.x,
                         "y": point.y,
                         "lng": coordinate.longitude,
                         "lat": coordinate.latitude,
                     ])
        }
    }
    
    private func getSelectedRoute(closeTo point: CGPoint) -> [Route]? {
        let tapCoordinate = mapView.convert(point, toCoordinateFrom: self.mapView)
        
        //do we have routes? If so, filter routes with at least 2 coordinates.
        guard let routes = self.originRoutes?.filter({ $0.coordinates?.count ?? 0 > 1 }) else { return nil }
        
        //Sort routes by closest distance to tap gesture.
        let closest = routes.sorted { (left, right) -> Bool in
            
            //existance has been assured through use of filter.
            let leftLine = Polyline(left.coordinates!)
            let rightLine = Polyline(right.coordinates!)
            let leftDistance = leftLine.closestCoordinate(to: tapCoordinate)!.distance
            let rightDistance = rightLine.closestCoordinate(to: tapCoordinate)!.distance
            
            return leftDistance < rightDistance
        }
        
        //filter closest coordinates by which ones are under threshold.
        let candidates = closest.filter {
            let closestCoordinate = Polyline($0.coordinates!).closestCoordinate(to: tapCoordinate)!.coordinate
            let closestPoint = mapView.convert(closestCoordinate, toPointTo: self.mapView)
            
            return closestPoint.distance(to: point) < tapGestureDistanceThreshold
        }
        return candidates
    }
    
    func showRouteWithIndex(index: Int,selectedRoute : Route){
        guard var updateRoutes = self.originRoutes else {return}
       updateRoutes.remove(at: index)
       updateRoutes.insert(selectedRoute, at: 0)
       self.showRoute(routes: updateRoutes, padding: self.padding)
    }
    
    /*
    *  UILongPressGestureRecognizer
    *  After a long press invoke the map#onMapLongClick callback.
    */
    @objc @IBAction func handleMapLongPress(sender: UILongPressGestureRecognizer) {
        //Fire when the long press starts
        if (sender.state == .began) {
          // Get the CGPoint where the user tapped.
            let point = sender.location(in: mapView)
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
            channel?.invokeMethod("map#onMapLongClick", arguments: [
                          "x": point.x,
                          "y": point.y,
                          "lng": coordinate.longitude,
                          "lat": coordinate.latitude,
                      ])
        }
        
    }
    
    
    
    /*
     *  MGLAnnotationControllerDelegate
     */
    func annotationController(_ annotationController: MGLAnnotationController, didSelect styleAnnotation: MGLStyleAnnotation) {
        annotationController.deselectStyleAnnotation(styleAnnotation)
        guard let channel = channel else {
            return
        }
        
        if let symbol = styleAnnotation as? MGLSymbolStyleAnnotation {
            channel.invokeMethod("symbol#onTap", arguments: ["symbol" : "\(symbol.identifier)"])
        } else if let circle = styleAnnotation as? MGLCircleStyleAnnotation {
            channel.invokeMethod("circle#onTap", arguments: ["circle" : "\(circle.identifier)"])
        } else if let line = styleAnnotation as? MGLLineStyleAnnotation {
            channel.invokeMethod("line#onTap", arguments: ["line" : "\(line.identifier)"])
        } else if let fill = styleAnnotation as? MGLPolygonStyleAnnotation {
            channel.invokeMethod("fill#onTap", arguments: ["fill" : "\(fill.identifier)"])
        }
    }
    
    // This is required in order to hide the default Maps SDK pin
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        if annotation is MGLUserLocation {
            return nil
        }
        return MGLAnnotationView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
    }
    
    /*
     *  MGLMapViewDelegate
     */
    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
        isMapReady = true
        updateMyLocationEnabled()
        
        if let initialTilt = initialTilt {
            let camera = mapView.camera
            camera.pitch = initialTilt
            mapView.setCamera(camera, animated: false)            
        }

        lineAnnotationController = MGLLineAnnotationController(mapView: self.mapView)
        lineAnnotationController!.annotationsInteractionEnabled = true
        lineAnnotationController?.delegate = self

        symbolAnnotationController = MGLSymbolAnnotationController(mapView: self.mapView)
        symbolAnnotationController!.annotationsInteractionEnabled = true
        symbolAnnotationController?.delegate = self
        
        circleAnnotationController = MGLCircleAnnotationController(mapView: self.mapView)
        circleAnnotationController!.annotationsInteractionEnabled = true
        circleAnnotationController?.delegate = self

        fillAnnotationController = MGLPolygonAnnotationController(mapView: self.mapView)
        fillAnnotationController!.annotationsInteractionEnabled = true
        fillAnnotationController?.delegate = self
        
        mapReadyResult?(nil)
        if let channel = channel {
            channel.invokeMethod("map#onStyleLoaded", arguments: nil)
        }
 
        if (gpsControlEnabled) {
            gpsControl?.alignBottom()
            gpsControl?.alignRight()
        }
    }
    
    func mapView(_ mapView: MGLMapView, shouldChangeFrom oldCamera: MGLMapCamera, to newCamera: MGLMapCamera) -> Bool {
        guard let bbox = cameraTargetBounds else { return true }
                
        // Get the current camera to restore it after.
        let currentCamera = mapView.camera
        
        // From the new camera obtain the center to test if it’s inside the boundaries.
        let newCameraCenter = newCamera.centerCoordinate
        
        // Set the map’s visible bounds to newCamera.
        mapView.camera = newCamera
        let newVisibleCoordinates = mapView.visibleCoordinateBounds
        
        // Revert the camera.
        mapView.camera = currentCamera
        
        // Test if the newCameraCenter and newVisibleCoordinates are inside bbox.
        let inside = MGLCoordinateInCoordinateBounds(newCameraCenter, bbox)
        let intersects = MGLCoordinateInCoordinateBounds(newVisibleCoordinates.ne, bbox) && MGLCoordinateInCoordinateBounds(newVisibleCoordinates.sw, bbox)
        
        return inside && intersects
    }
    
    func mapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage? {
        // Only for Symbols images should loaded.
        guard let symbol = annotation as? Symbol,
            let iconImageFullPath = symbol.iconImage else {
                return nil
        }
        // Reuse existing annotations for better performance.
        var annotationImage = mapView.dequeueReusableAnnotationImage(withIdentifier: iconImageFullPath)
        if annotationImage == nil {
            // Initialize the annotation image (from predefined assets symbol folder).
            if let range = iconImageFullPath.range(of: "/", options: [.backwards]) {
                let directory = String(iconImageFullPath[..<range.lowerBound])
                let assetPath = registrar.lookupKey(forAsset: "\(directory)/")
                let iconImageName = String(iconImageFullPath[range.upperBound...])
                let image = UIImage.loadFromFile(imagePath: assetPath, imageName: iconImageName)
                if let image = image {
                    annotationImage = MGLAnnotationImage(image: image, reuseIdentifier: iconImageFullPath)
                }
            }
        }
        return annotationImage
    }
    
    // On tap invoke the symbol#onTap callback.
    func mapView(_ mapView: MGLMapView, didSelect annotation: MGLAnnotation) {
        
       if let symbol = annotation as? Symbol {
            channel?.invokeMethod("symbol#onTap", arguments: ["symbol" : "\(symbol.id)"])
        }
    }
    
    // Allow callout view to appear when an annotation is tapped.
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        return true
    }

    func mapView(_ mapView: MGLMapView, didUpdate userLocation: MGLUserLocation?) {
        if let channel = channel, let userLocation = userLocation, let location = userLocation.location {
            channel.invokeMethod("map#onUserLocationUpdated", arguments: [
                "userLocation": location.toDict()
            ]);
       }
   }
   
    func mapView(_ mapView: MGLMapView, didChange mode: MGLUserTrackingMode, animated: Bool) {
        if let channel = channel {
            channel.invokeMethod("map#onCameraTrackingChanged", arguments: ["mode": mode.rawValue])
            if mode == .none {
                channel.invokeMethod("map#onCameraTrackingDismissed", arguments: [])
            }
        }
    }
    
    func mapViewDidBecomeIdle(_ mapView: MGLMapView) {
        if let channel = channel {
            channel.invokeMethod("map#onIdle", arguments: []);
        }
    }
    
    func mapView(_ mapView: MGLMapView, regionWillChangeAnimated animated: Bool) {
        if let channel = channel {
            channel.invokeMethod("camera#onMoveStarted", arguments: []);
        }
    }
    
    func mapViewRegionIsChanging(_ mapView: MGLMapView) {
        if !trackCameraPosition { return };
        if let channel = channel {
            channel.invokeMethod("camera#onMove", arguments: [
                "position": getCamera()?.toDict(mapView: mapView)
            ]);
        }
    }
    
    func mapView(_ mapView: MGLMapView, regionDidChangeAnimated animated: Bool) {
        if let channel = channel {
            channel.invokeMethod("camera#onIdle", arguments: []);
        }
    }
    
    /*
     *  MapboxMapOptionsSink
     */
    func setCameraTargetBounds(bounds: MGLCoordinateBounds?) {
        cameraTargetBounds = bounds
    }
    func setCompassEnabled(compassEnabled: Bool) {
        mapView.compassView.isHidden = compassEnabled
        mapView.compassView.isHidden = !compassEnabled
    }
    func setLogoEnabled(logoEnabled: Bool) {
        mapView.logoView.isHidden = !logoEnabled
    }
    func setMinMaxZoomPreference(min: Double, max: Double) {
        mapView.minimumZoomLevel = min
        mapView.maximumZoomLevel = max
    }
    func setStyleString(styleString: String) {
        // Check if json, url or plain string:
        if styleString.isEmpty {
            NSLog("setStyleString - string empty")
        } else if (styleString.hasPrefix("{") || styleString.hasPrefix("[")) {
            // Currently the iOS Mapbox SDK does not have a builder for json.
            NSLog("setStyleString - JSON style currently not supported")
        } else if (
            !styleString.hasPrefix("http://") && 
            !styleString.hasPrefix("https://") && 
            !styleString.hasPrefix("mapbox://")) {
            // We are assuming that the style will be loaded from an asset here.
            let assetPath = registrar.lookupKey(forAsset: styleString)
            mapView.styleURL = URL(string: assetPath, relativeTo: Bundle.main.resourceURL)
        } else {
            mapView.styleURL = URL(string: styleString)
        }
    }
    func setRotateGesturesEnabled(rotateGesturesEnabled: Bool) {
        mapView.allowsRotating = rotateGesturesEnabled
    }
    func setScrollGesturesEnabled(scrollGesturesEnabled: Bool) {
        mapView.allowsScrolling = scrollGesturesEnabled
    }
    func setTiltGesturesEnabled(tiltGesturesEnabled: Bool) {
        mapView.allowsTilting = tiltGesturesEnabled
    }
    func setTrackCameraPosition(trackCameraPosition: Bool) {
        self.trackCameraPosition = trackCameraPosition
    }
    func setZoomGesturesEnabled(zoomGesturesEnabled: Bool) {
        mapView.allowsZooming = zoomGesturesEnabled
    }
    func setMyLocationEnabled(myLocationEnabled: Bool) {
        if (self.myLocationEnabled == myLocationEnabled) {
            return
        }
        self.myLocationEnabled = myLocationEnabled
        updateMyLocationEnabled()
    }
    func setMyLocationTrackingMode(myLocationTrackingMode: MGLUserTrackingMode) {
        mapView.userTrackingMode = myLocationTrackingMode
    }
    func setMyLocationRenderMode(myLocationRenderMode: MyLocationRenderMode) {
        switch myLocationRenderMode {
        case .Normal:
            mapView.showsUserHeadingIndicator = false
        case .Compass:
            mapView.showsUserHeadingIndicator = true
        case .Gps:
            NSLog("RenderMode.GPS currently not supported")
        }
    }
    func setLogoViewMargins(x: Double, y: Double) {
        mapView.logoViewMargins = CGPoint(x: x, y: y)
    }
    func setCompassViewPosition(position: MGLOrnamentPosition) {
        mapView.compassViewPosition = position
    }
    func setCompassViewMargins(x: Double, y: Double) {
        mapView.compassViewMargins = CGPoint(x: x, y: y)
    }
    func setAttributionButtonMargins(x: Double, y: Double) {
        mapView.attributionButtonMargins = CGPoint(x: x, y: y)
    }

     //MARK: - VIETTELMAP API
    func locationUpdate(_ location: CLLocation!) {
        
    }
    
    func locationError(_ error: Error!) {
        
    }
    
    func changedMapStyleSuccess(_ vtmapStyle: VTMMapType) {
        
    }
    func changedMapStyleError() {
        
    }
}
