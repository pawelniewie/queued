//
//  QUAppDelegate.m
//  Queued
//
//  Created by Pawel Niewiadomski on 03.04.2013.
//  Copyright (c) 2013 Pawel Niewiadomski. All rights reserved.
//

#import "Buffered.h"
#import "MenubarController.h"
#import "QUAppDelegate.h"
#import "QUSignInWindowController.h"

@implementation QUAppDelegate

@synthesize panelController = _panelController;
@synthesize menubarController = _menubarController;

+ (QUAppDelegate *) instance {
    return (QUAppDelegate *) [[NSApplication sharedApplication] delegate];
}

#pragma mark -

- (void)dealloc
{
    [_panelController removeObserver:self forKeyPath:@"hasActivePanel"];
}

#pragma mark -

void *kContextActivePanel = &kContextActivePanel;

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == kContextActivePanel) {
        self.menubarController.hasActiveIcon = self.panelController.hasActivePanel;
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    // Install icon into the menu bar
    self.menubarController = [MenubarController new];
    
    _panelController = [[PanelController alloc] initWithDelegate:self];
    [_panelController addObserver:self forKeyPath:@"hasActivePanel" options:0 context:kContextActivePanel];
    
    _buffered = [[Buffered alloc] initApplication:@"Queued" withId:@"51607a104dbf08a338000006" andSecret:@"18b6c94f175555674bfd5274c9a3f3a0"];
    
    self.hasSignedIn = [_buffered isSignedIn:YES];
    
    if (!self.hasSignedIn) {
        [self showSignInWindow];
    }
}

- (void) showSignInWindow {
    @synchronized (self) {
        if (self.hasSignInWindowOpen) {
            [[NSRunningApplication currentApplication] activateWithOptions:NSApplicationActivateIgnoringOtherApps];
            return;
        }
        self.hasSignInWindowOpen = YES;
    }
    
    [self.buffered signInSheetModalForWindow:nil withCompletionHandler:^(NSError *error) {
        self.hasSignInWindowOpen = NO;
        if (error != nil) {
            if (error.code != kGTMOAuth2ErrorWindowClosed) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSAlert *alert = [NSAlert alertWithError:error];
                    [alert.window setTitle:@"Signing In to Buffer Failed"];
                    [alert runModal];
                });
            }
        } else {
            self.hasSignedIn = YES;
        }
    } withControllerClass:@"QUSignInWindowController"];

}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    // Explicitly remove the icon from the menu bar
    self.menubarController = nil;
    return NSTerminateNow;
}

#pragma mark - Actions

- (IBAction)togglePanel:(id)sender
{
    self.menubarController.hasActiveIcon = !self.menubarController.hasActiveIcon;
    self.panelController.hasActivePanel = self.menubarController.hasActiveIcon;
}

#pragma mark - PanelControllerDelegate

- (StatusItemView *)statusItemViewForPanelController:(PanelController *)controller
{
    return self.menubarController.statusItemView;
}

@end
