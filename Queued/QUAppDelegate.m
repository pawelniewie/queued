//
//  QUAppDelegate.m
//  Queued
//
//  Created by Pawel Niewiadomski on 03.04.2013.
//  Copyright (c) 2013 Pawel Niewiadomski. All rights reserved.
//

#import "QUAppDelegate.h"

@implementation QUAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    
}

- (void) awakeFromNib {
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [statusItem setMenu:self.statusMenu];
    [statusItem setHighlightMode:YES];
    NSImage *image = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Resources/icon" ofType:@"png"]];
    assert(image != nil);
    statusItem.image = image;
    statusItem.alternateImage = image;
}
@end
