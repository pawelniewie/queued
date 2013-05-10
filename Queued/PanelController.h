#import "BackgroundView.h"
#import "StatusItemView.h"

@class PanelController, QUPendingUpdatesViewController;

@protocol PanelControllerDelegate <NSObject>

@optional

- (StatusItemView *)statusItemViewForPanelController:(PanelController *)controller;

@end

#pragma mark -

@interface PanelController : NSWindowController <NSWindowDelegate> {
@private
    QUPendingUpdatesViewController *_pendingUpdatesViewController;
    BOOL _hasActivePanel;
}

@property (nonatomic, unsafe_unretained) IBOutlet BackgroundView *backgroundView;
@property (nonatomic, unsafe_unretained) IBOutlet NSView *pendingUpdates;
@property (nonatomic, unsafe_unretained) IBOutlet NSButton *signInButton;
@property (nonatomic, unsafe_unretained) IBOutlet NSButton *reloadButton;

@property (nonatomic) BOOL hasActivePanel;
@property (nonatomic, unsafe_unretained, readonly) id<PanelControllerDelegate> delegate;

- (id)initWithDelegate:(id<PanelControllerDelegate>)delegate;

- (void)openPanel;
- (void)closePanel;
- (IBAction)performSignIn:(id) sender;

@end
