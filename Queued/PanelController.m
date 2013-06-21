#import "Buffered.h"
#import "QUPendingUpdatesViewController.h"

#import "QUAppDelegate.h"
#import "PanelController.h"
#import "BackgroundView.h"
#import "StatusItemView.h"
#import "MenubarController.h"

#define POPUP_HEIGHT 600
#define PANEL_WIDTH 450

#pragma mark -

@implementation PanelController

#pragma mark -

- (id)initWithDelegate:(id<PanelControllerDelegate>)delegate
{
    self = [super initWithWindowNibName:@"PanelController"];
    if (self != nil)
    {
        _delegate = delegate;
        [[QUAppDelegate instance] addObserver:self forKeyPath:@"hasSignedIn" options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

- (void)dealloc
{
    [[QUAppDelegate instance] removeObserver:self forKeyPath:@"hasSignedIn"];
}

#pragma mark -
#pragma mark Button handlers 

- (IBAction)performSignIn:(id) sender {
    [self closePanel];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[QUAppDelegate instance] togglePanel:self];
        [[QUAppDelegate instance] showSignInWindow];
    });
}

#pragma mark -

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    // Make a fully skinned panel
    NSPanel *panel = (id)[self window];
    [panel setAcceptsMouseMovedEvents:YES];
    [panel setLevel:NSPopUpMenuWindowLevel];
    [panel setOpaque:NO];
    [panel setBackgroundColor:[NSColor clearColor]];
    
    // Resize panel
    NSRect panelRect = [[self window] frame];
    panelRect.size.height = POPUP_HEIGHT;
    [[self window] setFrame:panelRect display:NO];
    
    [_pendingUpdates addSubview:_pendingUpdatesViewController.view];
    
    NSDictionary *views = @{@"view" : _pendingUpdatesViewController.view};
    [_pendingUpdates addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|" options:0 metrics:nil views:views]];
    [_pendingUpdates addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|" options:0 metrics:nil views:views]];

    if ([QUAppDelegate instance].hasSignedIn) {
        [self initializePendingUpdates];
    }
}

- (void)initializePendingUpdates {
    [self.signInButton setHidden:YES];
    
    if (_pendingUpdatesViewController == nil) {
        _pendingUpdatesViewController = [[QUPendingUpdatesViewController alloc] initWithBuffered:[QUAppDelegate instance].buffered andProfilesMonitor:[[QUAppDelegate instance] profilesMonitor]];
        [_pendingUpdatesViewController.view setTranslatesAutoresizingMaskIntoConstraints:NO];
    }
}

#pragma mark - Public accessors

- (BOOL)hasActivePanel
{
    return _hasActivePanel;
}

- (void)setHasActivePanel:(BOOL)flag
{
    if (_hasActivePanel != flag)
    {
        _hasActivePanel = flag;
        
        if (_hasActivePanel)
        {
            [self openPanel];
        }
        else
        {
            [self closePanel];
        }
    }
}

#pragma mark - NSWindowDelegate

- (void)windowWillClose:(NSNotification *)notification
{
    self.hasActivePanel = NO;
}

- (void)windowDidResignKey:(NSNotification *)notification;
{
    if ([[self window] isVisible])
    {
        self.hasActivePanel = NO;
    }
}

- (void)windowDidResize:(NSNotification *)notification
{
    NSWindow *panel = [self window];
    NSRect statusRect = [self statusRectForWindow:panel];
    NSRect panelRect = [panel frame];
    
    CGFloat statusX = roundf(NSMidX(statusRect));
    CGFloat panelX = statusX - NSMinX(panelRect);
    
    self.backgroundView.arrowX = panelX;
    
    NSRect updatesRect = [self.pendingUpdates frame];
    updatesRect.size.width = NSWidth([self.backgroundView bounds]);
    updatesRect.size.height = NSHeight([self.backgroundView bounds]);
    [self.pendingUpdates setFrame:updatesRect];
}

#pragma mark - Keyboard

- (void)cancelOperation:(id)sender
{
    self.hasActivePanel = NO;
}

#pragma mark - Public methods

- (NSRect)statusRectForWindow:(NSWindow *)window
{
    NSRect screenRect = [[[NSScreen screens] objectAtIndex:0] frame];
    NSRect statusRect = NSZeroRect;
    
    StatusItemView *statusItemView = nil;
    if ([self.delegate respondsToSelector:@selector(statusItemViewForPanelController:)])
    {
        statusItemView = [self.delegate statusItemViewForPanelController:self];
    }
    
    if (statusItemView)
    {
        statusRect = statusItemView.globalRect;
        statusRect.origin.y = NSMinY(statusRect) - NSHeight(statusRect);
    }
    else
    {
        statusRect.size = NSMakeSize(STATUS_ITEM_VIEW_WIDTH, [[NSStatusBar systemStatusBar] thickness]);
        statusRect.origin.x = roundf((NSWidth(screenRect) - NSWidth(statusRect)) / 2);
        statusRect.origin.y = NSHeight(screenRect) - NSHeight(statusRect) * 2;
    }
    return statusRect;
}

- (void)openPanel
{
    NSWindow *panel = [self window];
    
    NSRect screenRect = [[[NSScreen screens] objectAtIndex:0] frame];
    NSRect statusRect = [self statusRectForWindow:panel];

    NSRect panelRect = [panel frame];
    panelRect.size.width = PANEL_WIDTH;
    panelRect.origin.x = roundf(NSMidX(statusRect) - NSWidth(panelRect) / 2);
    panelRect.origin.y = NSMaxY(statusRect) - NSHeight(panelRect);
    
    if (NSMaxX(panelRect) > (NSMaxX(screenRect) - ARROW_HEIGHT))
        panelRect.origin.x -= NSMaxX(panelRect) - (NSMaxX(screenRect) - ARROW_HEIGHT);
    
    [NSApp activateIgnoringOtherApps:NO];
    [panel setAlphaValue:1];
    [panel setFrame:panelRect display:YES];
    [panel makeKeyAndOrderFront:nil];
    
    if (![self.signInButton isHidden]) {
        [panel performSelector:@selector(makeFirstResponder:) withObject:self.signInButton afterDelay:0];
    }
}

- (void)closePanel
{
    [self.window orderOut:nil];
}

#pragma mark -
#pragma mark KVO
- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    NSLog(@"Changes to %@ %@", keyPath, change);
    if ([@"hasSignedIn" isEqualToString:keyPath] && [[change objectForKey:NSKeyValueChangeNewKey] boolValue]) {
        [self initializePendingUpdates];
    }
}
#pragma mark -
@end
