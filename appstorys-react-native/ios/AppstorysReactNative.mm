#import "AppstorysReactNative.h"

// TurboModule (New Architecture) entry point.
// getTurboModule references NativeAppstorysReactNativeSpecJSI which is generated
// by codegen once NativeAppstorysReactNativeSpec.ts exists. Until then this file
// compiles only under the Old Architecture path — New Architecture is deferred.
@implementation AppstorysReactNative

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params
{
    return std::make_shared<facebook::react::NativeAppstorysReactNativeSpecJSI>(params);
}

+ (NSString *)moduleName
{
    return @"AppstorysReactNative";
}

@end
