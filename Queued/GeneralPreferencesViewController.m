#import <ServiceManagement/ServiceManagement.h>

#import <MASShortcut/Shortcut.h>

#import "GeneralPreferencesViewController.h"

NSString *const kPreferenceGlobalShortcut = @"GlobalShortcut";

@implementation GeneralPreferencesViewController

- (id)init
{
    return [super initWithNibName:@"GeneralPreferencesView" bundle:nil];
}

- (NSString *)identifier
{
    return @"GeneralPreferences";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:NSImageNamePreferencesGeneral];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"General", @"Toolbar item name for the General preference pane");
}

- (void) loadView {
    [super loadView];
    
    self.shortcutView.associatedUserDefaultsKey = kPreferenceGlobalShortcut;
}

-(BOOL)startAutomatically {
    NSDictionary *dict = (NSDictionary*) CFBridgingRelease(SMJobCopyDictionary(kSMDomainUserLaunchd,
                                                                               CFSTR("com.pawelniewiadomski.Queued-Helper")));
    return (dict != NULL);
}

-(void)setStartAutomatically:(BOOL)startAutomatically {
    NSString *const potentialError = startAutomatically
            ? @"Couldn't add Helper App to launch at login item list." : @"Couldn't remove Helper App from launch at login item list.";
    
    // Turn on launch at login
    if (!SMLoginItemSetEnabled ((__bridge CFStringRef)@"com.pawelniewiadomski.Queued-Helper", startAutomatically)) {
        NSAlert *alert = [NSAlert alertWithMessageText:@"An error ocurred"
                                         defaultButton:@"OK"
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:potentialError];
        [alert runModal];
    }
}

@end
