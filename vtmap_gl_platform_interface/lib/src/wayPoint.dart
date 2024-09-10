part of vtmap_gl_platform_interface;

///A Geo-coordinate Point used for navigation.
class WayPoint {
  String? name;
  double? latitude;
  double? longitude;
  WayPoint({this.name, this.latitude, this.longitude});

  @override
  String toString() {
    return 'WayPoint{latitude: $latitude, longitude: $longitude}';
  }

  WayPoint.fromJson(Map<String, dynamic> json) {
    name = json["name"];
    latitude = json["latitude"] as double?;
    longitude = json["longitude"] as double?;
  }
}
