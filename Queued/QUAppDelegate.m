//
//  QUAppDelegate.m
//  Queued
//
//  Created by Pawel Niewiadomski on 03.04.2013.
//  Copyright (c) 2013 Pawel Niewiadomski. All rights reserved.
//

@import Accounts;
@import CoreData;

#import <Buffered.h>
#import <BUProfilesMonitor.h>
#import <BUPendingUpdatesMonitor.h>
#import <MASPreferences/MASPreferencesWindowController.h>
#import <MASShortcut/MASShortcut+UserDefaults.h>
#import <Sparkle/Sparkle.h>
#import <STTwitter/STTwitterAPI.h>

#import "MenubarController.h"
#import "QUAppDelegate.h"
#import "QUSignInWindowController.h"
#import "QUPostUpdateWindowController.h"
#import "QUPendingUpdatesViewController.h"
#import "QUFriendsFetcher.h"
#import "GeneralPreferencesViewController.h"

@interface QUAppDelegate()

@property (strong) NSMutableArray *friendsFetchers;

@end

@implementation QUAppDelegate

@synthesize hasSignedIn = _hasSignedIn;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize preferencesWindowController = _preferencesWindowController;

+(instancetype) instance {
    return (QUAppDelegate *) [[NSApplication sharedApplication] delegate];
}

#pragma mark -

- (void)dealloc
{
    [_profilesMonitor stopPoolling];
    [_panelController removeObserver:self forKeyPath:@"hasActivePanel"];
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
        NSArray *profiles = change[NSKeyValueChangeNewKey];
        [profiles enumerateObjectsUsingBlock:^(BUProfile *profile, NSUInteger idx, BOOL *stop) {
            if (!profile.updatesMonitor.isPooling) {
                [profile.updatesMonitor refresh];
                [profile.updatesMonitor startPoolingWithInterval:30];
            }
        }];
        [[NSNotificationCenter defaultCenter] postNotificationName:QUProfilesLoadedNotification object:profiles userInfo:nil];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - NSApplicationDelegate

-(void) applicationWillFinishLaunching:(NSNotification *)notification {
    [SUUpdater sharedUpdater].sendsSystemProfile = YES;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    // Install icon into the menu bar
    self.menubarController = [MenubarController new];
    
    _panelController = [[PanelController alloc] initWithDelegate:self];
    [_panelController addObserver:self forKeyPath:@"hasActivePanel" options:0 context:kContextActivePanel];
    
    // Execute your block of code automatically when user triggers a shortcut from preferences
    [MASShortcut registerGlobalShortcutWithUserDefaultsKey:kPreferenceGlobalShortcut handler:^{
//        _panelController.hasActivePanel = YES;
        [self postUpdate:self];
    }];
    
    _accountStore = [self newAccountStore];
    _twitterType = [[self accountStore] accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    [self.accountStore requestAccessToAccountsWithType:self.twitterType options:nil completion:^(BOOL granted, NSError *error) {
        if (granted) {
            [self performSelectorOnMainThread:@selector(updateTwitterAccounts) withObject:nil waitUntilDone:NO];
        }
    }];

    _buffered = [[Buffered alloc] initApplication:@"Queued" withId:@"51607a104dbf08a338000006" andSecret:@"18b6c94f175555674bfd5274c9a3f3a0"];
    _profilesMonitor = [[BUProfilesMonitor alloc] initWithBuffered: _buffered];
    [_profilesMonitor addObserver:self forKeyPath:@"profiles" options:NSKeyValueObservingOptionNew context:nil];
    
    self.hasSignedIn = [_buffered isSignedIn:YES];
    
    if (!self.hasSignedIn) {
        [self showSignInWindow];
    }
    }

- (ACAccountStore*) newAccountStore {
    return [ACAccountStore new];
}

- (void) updateTwitterAccounts {
    if (self.friendsFetchers == nil) {
        self.friendsFetchers = [@[] mutableCopy];
    }
    
    NSArray *twitterAccounts = [self.accountStore accountsWithAccountType:self.twitterType];
    [twitterAccounts enumerateObjectsUsingBlock:^(ACAccount* account, NSUInteger idx, BOOL *stop) {
        QUFriendsFetcher *fetcher = [[QUFriendsFetcher alloc] initWithAccount: account];

        [fetcher startFetching];
        [self.friendsFetchers addObject:fetcher];
        
    }];
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

- (IBAction)postUpdate:(id)sender
{
    if (_postUpdateWindow == nil) {
        _postUpdateWindow = [[QUPostUpdateWindowController alloc] initWithBuffered:self.buffered andProfilesMonitor:self.profilesMonitor];
    }
    [_postUpdateWindow.window center];
    [_postUpdateWindow showWindow:self];
    [_postUpdateWindow.window setLevel:NSFloatingWindowLevel];
}

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
    NSString* mailtoLink = [NSString stringWithFormat:@"mailto:pawelniewiadomski@me.com?subject=Queued Feedback&body=If it's a bug report please write as much details as you can think of (how to reproduce the bug).\n\nThanks for contributing!\n\nThe version is %@\n", [[NSBundle mainBundle] infoDictionary][@"FullVersion"]];
                           
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
    [self.profilesMonitor.profiles enumerateObjectsUsingBlock:^(BUProfile* obj, NSUInteger idx, BOOL *stop) {
        [obj.updatesMonitor refresh];
    }];
}

#pragma mark -
#pragma mark Core Data
- (NSURL *)applicationDocumentsDirectory
{
    return [[[[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:@"Queued"];
}

- (void)saveContext
{
    NSManagedObjectContext *objectContext = self.managedObjectContext;
    if (objectContext != nil)
    {
        [objectContext performBlock:^{
            NSError *error = nil;
            if ([objectContext hasChanges] && ![objectContext save:&error])
            {
                NSLog(@"Unresolved error saving data %@, %@", error, [error userInfo]);
            }
        }];
    }
}

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil)
    {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil)
    {
        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil)
    {
        return _managedObjectModel;
    }
    
    _managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    
    return _managedObjectModel;
}

/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil)
    {
        return _persistentStoreCoordinator;
    }
    
    NSURL *documentsDir = [self applicationDocumentsDirectory];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if(![fileManager fileExistsAtPath:documentsDir.path])
        if(![fileManager createDirectoryAtPath:documentsDir.path withIntermediateDirectories:YES attributes:nil error:NULL])
            NSLog(@"Error: Create folder failed %@", documentsDir);
    
    NSURL *storeURL = [documentsDir URLByAppendingPathComponent:@"Queued.sqlite"];
    
    NSError *error = nil;
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error])
    {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}
#pragma mark -
#pragma mark Preferences
- (NSWindowController *)preferencesWindowController
{
    if (_preferencesWindowController == nil)
    {
        NSViewController *generalViewController = [GeneralPreferencesViewController new];
        NSArray *controllers = @[generalViewController];
        
        // To add a flexible space between General and Advanced preference panes insert [NSNull null]:
        //     NSArray *controllers = [[NSArray alloc] initWithObjects:generalViewController, [NSNull null], advancedViewController, nil];
        
        NSString *title = NSLocalizedString(@"Preferences", @"Common title for Preferences window");
        _preferencesWindowController = [[MASPreferencesWindowController alloc] initWithViewControllers:controllers title:title];
    }
    return _preferencesWindowController;
}

- (IBAction)showPreferences:(id)sender
{
    [self.preferencesWindowController.window center];
    [self.preferencesWindowController showWindow:self];
    [self.preferencesWindowController.window setLevel:NSFloatingWindowLevel];
}

#pragma mark -
@end
