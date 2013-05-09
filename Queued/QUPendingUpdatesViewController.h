//
//  BUPendingUpdatesViewController.h
//  Buffered
//
//  Created by Pawel Niewiadomski on 01.04.2013.
//  Copyright (c) 2013 Pawel Niewiadomski. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <BUProfilesMonitor.h>

@interface QUPendingUpdatesViewController : NSViewController<NSTableViewDataSource, NSTabViewDelegate> {
@private
    Buffered __weak *_buffered;
    BUProfilesMonitor __weak *_profilesMonitor;
    NSMutableArray *_observedVisibleItems;
    UpdatesCompletionHandler _updatesHandler;
    NSTimer *updateTimer;
}

@property (weak) IBOutlet NSProgressIndicator *progress;
@property (weak) IBOutlet NSTableView *updatesTable;

@property (strong) NSArrayController *profiles;
@property (strong) NSMutableDictionary *updates;
@property (strong) NSArrayController *updatesContent;
@property (weak) id<BUErrorDelegate> delegate;

- (id) initWithBuffered: (Buffered *) buffered andProfilesMonitor: (BUProfilesMonitor *) profilesMonitor;
- (void) stopTimer;

@end
