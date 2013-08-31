//
//  QUBufferPreferencesViewController.m
//  Queued
//
//  Created by Pawel Niewiadomski on 31.08.2013.
//  Copyright (c) 2013 Pawel Niewiadomski. All rights reserved.
//

#import "QUBufferPreferencesViewController.h"

@interface QUBufferPreferencesViewController ()

@end

@implementation QUBufferPreferencesViewController

- (id)init
{
    return [super initWithNibName:@"QUBufferPreferencesViewController" bundle:nil];
}

- (NSString *)identifier
{
    return @"BufferPreferences";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:@"BufferLogo"];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Buffer", @"Toolbar item name for the Buffer preference pane");
}


@end
