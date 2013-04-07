#import "Panel.h"
#import "QUAppDelegate.h"

@implementation Panel

- (BOOL)canBecomeKeyWindow;
{
    return YES; // Allow Search field to become the first responder
}

@end
