//
//  QUBrowserTracker.m
//  Queued
//
//  Created by Pawel Niewiadomski on 26.09.2013.
//  Copyright (c) 2013 Pawel Niewiadomski. All rights reserved.
//

#import "Scripting Bridge/GoogleChrome.h"
#import "Scripting Bridge/Safari.h"
#import "QUBrowserTracker.h"

NSString* const SafariBundleId = @"com.apple.Safari";
NSString* const ChromeBundleId = @"com.google.Chrome";

@implementation QUBrowserTracker

- (instancetype) init {
    self = [super init];
    if (self) {
        // Check if switching from Safari or Chrome
        [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(applicationDidBecomeInactive:) name:NSWorkspaceDidDeactivateApplicationNotification object:nil];
    }
    return self;
}

- (void) applicationDidBecomeInactive: (NSNotification*) notification {
    NSDictionary *userInfo = [notification userInfo];
    if (userInfo == nil) {
        return;
    }
    NSRunningApplication *application = userInfo[NSWorkspaceApplicationKey];
    if (application == nil) {
        return;
    }
    self.hasSwitchedFromBrowser = NO;
    _browserActiveUrl = nil;
    if ([SafariBundleId isEqualToString: application.bundleIdentifier]) {
        self.hasSwitchedFromBrowser = YES;
        SafariApplication* safari = [SBApplication applicationWithBundleIdentifier:SafariBundleId];
        for (SafariWindow *window in safari.windows) {
            if ([window visible]) {
                _browserActiveUrl = window.currentTab.URL;
                break;
            }
        }
    }
    if ([ChromeBundleId isEqualToString:application.bundleIdentifier]) {
        self.hasSwitchedFromBrowser = YES;
        GoogleChromeApplication *application = [SBApplication applicationWithBundleIdentifier:ChromeBundleId];
        for (GoogleChromeWindow *window in application.windows) {
            if ([window visible]) {
                _browserActiveUrl = ((GoogleChromeTab *)window.tabs[window.activeTabIndex]).URL;
                break;
            }
        }
    }
}

- (void) dealloc {
    [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
}

@end
