//
//  QUAppDelegate.h
//  Queued
//
//  Created by Pawel Niewiadomski on 03.04.2013.
//  Copyright (c) 2013 Pawel Niewiadomski. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PanelController.h"

@class MenubarController, Buffered, QUSignInWindowController;

@interface QUAppDelegate : NSObject <NSApplicationDelegate, PanelControllerDelegate>

@property (nonatomic, strong) MenubarController *menubarController;
@property (nonatomic, strong, readonly) PanelController *panelController;
@property (nonatomic, strong, readonly) Buffered *buffered;
@property (assign) BOOL hasSignedIn;
@property (assign) BOOL hasSignInWindowOpen;

- (IBAction)togglePanel:(id)sender;
- (void) showSignInWindow;

+ (QUAppDelegate *) instance;

@end

