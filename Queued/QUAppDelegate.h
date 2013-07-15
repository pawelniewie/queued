//
//  QUAppDelegate.h
//  Queued
//
//  Created by Pawel Niewiadomski on 03.04.2013.
//  Copyright (c) 2013 Pawel Niewiadomski. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PanelController.h"

@class MenubarController, Buffered, QUSignInWindowController, BUProfilesMonitor, QUPostUpdateWindowController;

@interface QUAppDelegate : NSObject <NSApplicationDelegate, PanelControllerDelegate>

@property (nonatomic, strong) MenubarController *menubarController;
@property (nonatomic, strong, readonly) PanelController *panelController;
@property (nonatomic, strong, readonly) Buffered *buffered;
@property (nonatomic, strong, readonly) BUProfilesMonitor *profilesMonitor;
@property (nonatomic, strong, readonly) QUPostUpdateWindowController *postUpdateWindow;

@property (assign) BOOL hasSignedIn;
@property (assign) BOOL hasSignInWindowOpen;
@property (assign, readonly) BOOL isLaunchAtLoginEnabled;

- (IBAction)togglePanel:(id)sender;
- (IBAction)reloadPendingUpdates:(id)sender;
- (void) showSignInWindow;
-(IBAction)toggleLaunchAtLogin:(id)sender;

+ (QUAppDelegate *) instance;

@end

