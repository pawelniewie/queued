//
//  QUPostUpdateWindowController.h
//  Queued
//
//  Created by Pawel Niewiadomski on 14.07.2013.
//  Copyright (c) 2013 Pawel Niewiadomski. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Buffered, BUProfilesMonitor;

@interface QUPostUpdateWindowController : NSWindowController<NSCollectionViewDelegate> {
@private
    __weak Buffered *_buffered;
    __weak BUProfilesMonitor  *_profilesMonitor;
}

@property (weak) IBOutlet NSButton *sendButton;
@property (unsafe_unretained) IBOutlet NSTextView *text;
@property (strong) IBOutlet NSArrayController *profiles;
@property (weak) IBOutlet NSCollectionView *profilesCollectionView;

- (IBAction)cancel:(id)sender;
- (IBAction)send:(id)sender;

- (instancetype) initWithBuffered: (Buffered *) buffered andProfilesMonitor: (BUProfilesMonitor *) profilesMonitor;

@end
