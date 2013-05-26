//
//  QUAppDelegate.m
//  Queued
//
//  Created by Pawel Niewiadomski on 03.04.2013.
//  Copyright (c) 2013 Pawel Niewiadomski. All rights reserved.
//

#import <Buffered.h>
#import <BUProfilesMonitor.h>
#import <BUPendingUpdatesMonitor.h>
#import <BUPendingUpdatesViewController.h>
#import <ServiceManagement/ServiceManagement.h>

#import "MenubarController.h"
#import "QUAppDelegate.h"
#import "QUSignInWindowController.h"

@implementation QUAppDelegate

@synthesize hasSignedIn = _hasSignedIn;

+ (QUAppDelegate *) instance {
    return (QUAppDelegate *) [[NSApplication sharedApplication] delegate];
}

#pragma mark -

- (void)dealloc
{
    [_profilesMonitor stopPoolling];
    [_panelController removeObserver:self forKeyPath:@"hasActivePanel"];
}

#pragma mark -
#pragma mark Start At Login
-(BOOL)isLaunchAtLoginEnabled {
    NSDictionary *dict = (NSDictionary*) CFBridgingRelease(SMJobCopyDictionary(kSMDomainUserLaunchd,
                                                            CFSTR("com.pawelniewiadomski.Queued-Helper")));
    return (dict != NULL);
}

-(IBAction)toggleLaunchAtLogin:(NSMenuItem *)sender
{
    BOOL shouldLaunchAtLoginBeEnabled = !self.isLaunchAtLoginEnabled;
    NSString *const potentialError = shouldLaunchAtLoginBeEnabled ? @"Couldn't add Helper App to launch at login item list." : @"Couldn't remove Helper App from launch at login item list.";

    // Turn on launch at login
    [self willChangeValueForKey:@"isLaunchAtLoginEnabled"];
    if (!SMLoginItemSetEnabled ((__bridge CFStringRef)@"com.pawelniewiadomski.Queued-Helper", shouldLaunchAtLoginBeEnabled)) {
        NSAlert *alert = [NSAlert alertWithMessageText:@"An error ocurred"
                                         defaultButton:@"OK"
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:potentialError];
        [alert runModal];
    }
    [self didChangeValueForKey:@"isLaunchAtLoginEnabled"];
}
#pragma mark -
#pragma mark KVO
void *kContextActivePanel = &kContextActivePanel;

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == kContextActivePanel) {
        self.menubarController.hasActiveIcon = self.panelController.hasActivePanel;
    }
    else if ([@"profiles" isEqualToString:keyPath]) {
        NSLog(@"Profiles were updated %@", change);
        NSArray *profiles = [change objectForKey:NSKeyValueChangeNewKey];
        [profiles enumerateObjectsUsingBlock:^(Profile *profile, NSUInteger idx, BOOL *stop) {
            if (!profile.updatesMonitor.isPooling) {
                [profile.updatesMonitor refresh];
                [profile.updatesMonitor startPoolingWithInterval:30];
            }
        }];
        [[NSNotificationCenter defaultCenter] postNotificationName:BUProfilesLoadedNotification object:profiles userInfo:nil];
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
    _profilesMonitor = [[BUProfilesMonitor alloc] initWithBuffered: _buffered];
    [_profilesMonitor addObserver:self forKeyPath:@"profiles" options:NSKeyValueObservingOptionNew context:nil];
    
    self.hasSignedIn = [_buffered isSignedIn:YES];
    
    if (!self.hasSignedIn) {
        [self showSignInWindow];
    }
}

- (BOOL) hasSignedIn {
    @synchronized(self) {
        return _hasSignedIn;
    }
}

- (void) setHasSignedIn: (BOOL) signedIn {
    @synchronized(self) {
        _hasSignedIn = signedIn;
        if (_hasSignedIn) {
            [_profilesMonitor refresh];
            [_profilesMonitor startPoolingWithInterval:60.0];
        }
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

- (IBAction)sendFeedback:(id)sender {
    // This line defines our entire mailto link. Notice that the link is formed
    // like a standard GET query might be formed, with each parameter, subject
    // and body, follow the email address with a ? and are separated by a &.
    // I use the %@ formatting string to add the contents of the lastResult and
    // songData objects to the body of the message. You should change these to
    // whatever information you want to include in the body.
    NSString* mailtoLink = [NSString stringWithFormat:@"mailto:pawelniewiadomski@me.com?subject=Queued Feedback&body=If it's a bug report please write as much details as you can think of (how to reproduce the bug).\n\nThanks for contributing!\n\nThe version is %@\n", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"FullVersion"]];
                           
    // This creates a URL string by adding percent escapes. Since the URL is
    // just being used locally, I don't know if this is always necessary,
    // however I thought it would be a good idea to stick to standards.
    NSURL* url = [NSURL URLWithString:(NSString*)
         CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)mailtoLink,
             NULL, NULL, kCFStringEncodingUTF8))];
    
    [[NSWorkspace sharedWorkspace] openURL:url];
}

#pragma mark - PanelControllerDelegate

- (StatusItemView *)statusItemViewForPanelController:(PanelController *)controller
{
    return self.menubarController.statusItemView;
}

- (IBAction)reloadPendingUpdates:(id)sender {
    [self.profilesMonitor.profiles enumerateObjectsUsingBlock:^(Profile* obj, NSUInteger idx, BOOL *stop) {
        [obj.updatesMonitor refresh];
    }];
}

@end
