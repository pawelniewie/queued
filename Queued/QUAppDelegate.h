//
//  QUAppDelegate.h
//  Queued
//
//  Created by Pawel Niewiadomski on 03.04.2013.
//  Copyright (c) 2013 Pawel Niewiadomski. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface QUAppDelegate : NSObject <NSApplicationDelegate> {
    @private
    NSStatusItem * statusItem;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSMenu *statusMenu;

@end
