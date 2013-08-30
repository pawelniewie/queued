#import "MASPreferencesViewController.h"

@class MASShortcutView;

NSString *const kPreferenceGlobalShortcut;

@interface GeneralPreferencesViewController : NSViewController <MASPreferencesViewController>
@property (weak) IBOutlet NSButton *startAutomaticallyButton;
@property (weak) IBOutlet MASShortcutView *shortcutView;
@property (assign) BOOL startAutomatically;
@end
