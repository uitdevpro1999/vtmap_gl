# Flutter VTMaps GL

> **Please note that this project is community driven and is not an official VTMaps product.** We welcome [feedback](https://github.com/tobrun/flutter-VTMap-gl/issues) and contributions.

This Flutter plugin allows to show embedded interactive and customizable vector maps inside a Flutter widget. For the Android and iOS integration, we use [VTMap-gl-native](https://github.com/VTMap/VTMap-gl-native). For web, we rely on [VTMap-gl-js](https://github.com/VTMap/VTMap-gl-js). This project only supports a subset of the API exposed by these libraries. 

![screenshot.png](screenshot.png)

## Running the example app

- Install [Flutter](https://flutter.io/get-started/) and validate its installation with `flutter doctor`
- Clone the repository with `git clone git@github.com:tobrun/flutter-VTMap-gl.git`
- Add a VTMap access token to the example app (see next section)
- Connect a mobile device or start an emulator, simulator or chrome
- Locate the id of a the device with `flutter devices`
- Run the app with `cd flutter_VTMap/example && flutter packages get && flutter run -d {device_id}`

## Adding a VTMaps Access Token

This project uses VTMaps vector tiles, which requires a VTMaps account and a VTMaps access token. Obtain a free access token on [your VTMaps account page](https://account.viettelmaps.vn/).
> **Even if you do not use VTMaps vector tiles but vector tiles from a different source (like self-hosted tiles) with this plugin, you will need to specify any non-empty string as Access Token as explained below!**


The **recommended** way to provide your access token is through the `VTMaps` constructor's `accessToken` parameter, which is available starting from the v0.8 release. Note that you should always use the same token throughout your entire app.

An alternative method to provide access tokens that was required until the v0.7 release is described in [this wiki article](https://github.com/tobrun/flutter-VTMap-gl/wiki/VTMap-access-tokens).

## Using the SDK in your project

This project is available on [pub.dev](https://pub.dev/packages/VTMap_gl), follow the [instructions](https://flutter.dev/docs/development/packages-and-plugins/using-packages#adding-a-package-dependency-to-an-app) to integrate a package into your flutter application. For platform specific integration, use the flutter application under the example folder as reference. 

## Supported API

| Feature | Android | iOS | Web |
| ------ | ------ | ----- | ----- |
| Style | :white_check_mark:   | :white_check_mark: | :white_check_mark: |
| Camera | :white_check_mark:   | :white_check_mark: | :white_check_mark: |
| Gesture | :white_check_mark:   | :white_check_mark: | :white_check_mark: |
| User Location | :white_check_mark: | :white_check_mark: | :white_check_mark: |
| Symbol | :white_check_mark:   | :white_check_mark: | :white_check_mark: |
| Circle | :white_check_mark:   | :white_check_mark: | :white_check_mark: |
| Line | :white_check_mark:   | :white_check_mark: | :white_check_mark: |
| Fill | :white_check_mark:   | :white_check_mark: |  |

## Map Styles

Map styles can be supplied by setting the `styleString` in the `MapOptions`. The following formats are supported:

1. Passing the URL of the map style. This can be one of the built-in map styles, also see `VTMapStyles` or a custom map style served remotely using a URL that start with 'http(s)://'
2. Passing the style as a local asset. Create a JSON file in the `assets` and add a reference in `pubspec.yml`. Set the style string to the relative path for this asset in order to load it into the map.
3. Passing the raw JSON of the map style. This is only supported on Android.  

## Offline Sideloading

Support for offline maps is available by *"side loading"* the required map tiles and including them in your `assets` folder.

* Create your tiles package by following the guide available [here](https://docs.VTMap.com/ios/maps/overview/offline/).

* Place the tiles.db file generated in step one in your assets directory and add a reference to it in your `pubspec.yml` file.

```
   assets:
     - assets/cache.db
```

* Call `installOfflineMapTiles` when your application starts to copy your tiles into the location where VTMap can access them.  **NOTE:** This method should be called **before** the Map widget is loaded to prevent collisions when copying the files into place.
 
```
    try {
      await installOfflineMapTiles(join("assets", "cache.db"));
    } catch (err) {
      print(err);
    }
```

## Location features
To enable location features in an **Android** application:

You need to declare the `ACCESS_COARSE_LOCATION` or `ACCESS_FINE_LOCATION` permission in the AndroidManifest.xml and starting from Android API level 23 also request it at runtime. The plugin does not handle this for you. The example app uses the flutter ['location' plugin](https://pub.dev/packages/location) for this. 

To enable location features in an **iOS** application:

If you access your users' location, you should also add the following key to your Info.plist to explain why you need access to their location data:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>[Your explanation here]</string>
```

VTMap [recommends](https://docs.VTMap.com/help/tutorials/first-steps-ios-sdk/#display-the-users-location) the explanation "Shows your location on the map and helps improve the map".

## Documentation

This README file currently houses all of the documentation for this Flutter project. Please visit [VTMap.com/android-docs](https://www.VTMap.com/android-docs/) if you'd like more information about the VTMap Maps SDK for Android and [VTMap.com/ios-sdk](https://www.VTMap.com/ios-sdk/) for more information about the VTMap Maps SDK for iOS.

## Getting Help

- **Need help with your code?**: Look for previous questions on the [#VTMap tag](https://stackoverflow.com/questions/tagged/VTMap+flutter) — or [ask a new question](https://stackoverflow.com/questions/tagged/VTMap+android).
- **Have a bug to report?** [Open an issue](https://github.com/tobrun/flutter-VTMap-gl/issues/new). If possible, include a full log and information which shows the issue.
- **Have a feature request?** [Open an issue](https://github.com/tobrun/flutter-VTMap-gl/issues/new). Tell us what the feature should do and why you want the feature.


## Contributing

We welcome contributions to this repository! If you're interested in helping build this VTMap/Flutter integration, please read [the contribution guide](https://github.com/tobrun/flutter-VTMap-gl/blob/master/CONTRIBUTING.md) to learn how to get started.
