//
//  QUBrowserTracker.h
//  Queued
//
//  Created by Pawel Niewiadomski on 26.09.2013.
//  Copyright (c) 2013 Pawel Niewiadomski. All rights reserved.
//

#import <Foundation/Foundation.h>

NSString* const SafariBundleId;
NSString* const ChromeBundleId;

@interface QUBrowserTracker : NSObject

@property (assign) BOOL hasSwitchedFromBrowser;
@property (strong, readonly) NSString* browserActiveUrl;

@end
