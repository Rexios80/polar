#import "PolarPlugin.h"
#if __has_include(<polar/polar-Swift.h>)
#import <polar/polar-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "polar-Swift.h"
#endif

@implementation PolarPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftPolarPlugin registerWithRegistrar:registrar];
}
@end
