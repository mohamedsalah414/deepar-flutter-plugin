#import "DeepArPlugin.h"
#if __has_include(<deep_ar/deep_ar-Swift.h>)
#import <deep_ar/deep_ar-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "deep_ar-Swift.h"
#endif

@implementation DeepArPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftDeepArPlugin registerWithRegistrar:registrar];
}
@end
