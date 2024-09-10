#import "MapboxMapsPlugin.h"
#import <vtmap_gl/vtmap_gl-Swift.h>

@implementation MapboxMapsPlugin 
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftMapboxGlFlutterPlugin registerWithRegistrar:registrar];
}
@end
