//
//  QUAppDelegate.h
//  Queued
//
//  Created by Pawel Niewiadomski on 03.04.2013.
//  Copyright (c) 2013 Pawel Niewiadomski. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <Sparkle/Sparkle.h>

#import "PanelController.h"

@class MenubarController, Buffered, QUSignInWindowController, BUProfilesMonitor, QUPostUpdateWindowController, QUBrowserTracker;
@class ACAccountStore, ACAccountType, NSManagedObjectContext, NSManagedObjectModel, NSPersistentStoreCoordinator;

@interface QUAppDelegate : NSObject <NSApplicationDelegate, PanelControllerDelegate, SUUpdaterDelegate>

@property (nonatomic, strong) MenubarController *menubarController;
@property (nonatomic, strong, readonly) PanelController *panelController;
@property (nonatomic, strong, readonly) Buffered *buffered;
@property (nonatomic, strong, readonly) BUProfilesMonitor *profilesMonitor;
@property (nonatomic, strong, readonly) QUPostUpdateWindowController *postUpdateWindow;
@property (nonatomic, strong, readonly) NSWindowController *preferencesWindowController;

@property (assign) BOOL hasSignedIn;
@property (assign) BOOL hasSignInWindowOpen;

@property (strong,readonly) ACAccountType* twitterType;
@property (strong,readonly) ACAccountStore* accountStore;
@property (strong,readonly) QUBrowserTracker* browserTracker;
@property (strong,readonly) NSRunningApplication* previousApplication;

@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

- (IBAction)togglePanel:(id)sender;
- (IBAction)reloadPendingUpdates:(id)sender;
- (void) showSignInWindow;

- (void) activatePreviousApplication;

+ (instancetype) instance;

@end

