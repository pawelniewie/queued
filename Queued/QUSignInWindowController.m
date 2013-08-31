//
//  QUSignInWindowController.m
//  Queued
//
//  Created by Pawel Niewiadomski on 07.04.2013.
//  Copyright (c) 2013 Pawel Niewiadomski. All rights reserved.
//

#import "QUSignInWindowController.h"

@interface QUSignInWindowController ()

@end

@implementation QUSignInWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    [self.window setLevel:NSFloatingWindowLevel];
    [self.window center];
    [self.window makeKeyAndOrderFront:self];
}

+ (NSString *)authNibName {
    return @"QUSignInWindowController";
}

@end
