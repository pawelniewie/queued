//
//  QUBrowserTracker.m
//  Queued
//
//  Created by Pawel Niewiadomski on 26.09.2013.
//  Copyright (c) 2013 Pawel Niewiadomski. All rights reserved.
//

#import "QUBrowserTracker.h"

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
    _browserBundleIdentifier = nil;
    if ([@"com.apple.Safari" isEqualToString: application.bundleIdentifier]) {
        self.hasSwitchedFromBrowser = YES;
        _browserBundleIdentifier = @"com.apple.Safari";
    }
    if ([@"com.google.Chrome" isEqualToString:application.bundleIdentifier]) {
        self.hasSwitchedFromBrowser = YES;
        _browserBundleIdentifier = @"com.google.Chrome";
    }
}

- (void) dealloc {
    [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
}

@end
