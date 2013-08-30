#import <MASShortcut/MASShortcutView+UserDefaults.h>

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

@end
