//
// This is a sample General preference pane
//

#import "MASPreferencesViewController.h"

@class MASShortcutView;

NSString *const kPreferenceGlobalShortcut;

@interface GeneralPreferencesViewController : NSViewController <MASPreferencesViewController>
@property (weak) IBOutlet NSButton *startAutomatically;
@property (weak) IBOutlet MASShortcutView *shortcutView;
@end
