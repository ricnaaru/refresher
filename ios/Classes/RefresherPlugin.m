#import "RefresherPlugin.h"
#import <refresher/refresher-Swift.h>

@implementation RefresherPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftRefresherPlugin registerWithRegistrar:registrar];
}
@end
