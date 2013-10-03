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

+ (NSString *) browserActiveUrl:(NSRunningApplication *)application {
    if (application == nil) {
        return nil;
    }

    if ([SafariBundleId isEqualToString: application.bundleIdentifier]) {
        SafariApplication* safari = [SBApplication applicationWithBundleIdentifier:SafariBundleId];
        for (SafariWindow *window in safari.windows) {
            if ([window visible]) {
                return [[window currentTab] URL];
            }
        }
    }
    if ([ChromeBundleId isEqualToString:application.bundleIdentifier]) {
        GoogleChromeApplication *application = [SBApplication applicationWithBundleIdentifier:ChromeBundleId];
        for (GoogleChromeWindow *window in application.windows) {
            if ([window visible]) {
                return [[window activeTab] URL];
            }
        }
    }
    return nil;
}

@end
