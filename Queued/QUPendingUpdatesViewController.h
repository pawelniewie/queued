//
//  BUPendingUpdatesViewController.h
//  Buffered
//
//  Created by Pawel Niewiadomski on 01.04.2013.
//  Copyright (c) 2013 Pawel Niewiadomski. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <BUProfilesMonitor.h>

FOUNDATION_EXPORT NSString * const QUProfilesLoadedNotification;
FOUNDATION_EXPORT NSString * const QUPendingUpdatesLoadedNotification;

@interface QUPendingUpdatesViewController : NSViewController<NSTableViewDataSource, NSTabViewDelegate> {
@private
    __weak Buffered *_buffered;
    __weak BUProfilesMonitor  *_profilesMonitor;
    NSMutableArray *_observedVisibleItems;
    UpdatesCompletionHandler _updatesHandler;
    RemoveCompletionHandler _removeHandler;
}

@property (weak) IBOutlet NSProgressIndicator *progress;
@property (weak) IBOutlet NSTableView *updatesTable;
@property (nonatomic, unsafe_unretained) IBOutlet NSButton *reloadButton;
@property (nonatomic, unsafe_unretained) IBOutlet NSButton *removeButton;
@property (nonatomic, unsafe_unretained) IBOutlet NSMenuItem *launchAtLoginMenuItem;
@property (nonatomic, unsafe_unretained) IBOutlet NSArrayController *updatesContent;

@property (strong) NSArrayController *profiles;
@property (strong) NSMutableDictionary *updates;
@property (weak) id<BUErrorDelegate> delegate;

- (id) initWithBuffered: (Buffered *) buffered andProfilesMonitor: (BUProfilesMonitor *) profilesMonitor;

@end
