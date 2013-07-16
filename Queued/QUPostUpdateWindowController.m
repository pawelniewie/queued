//
//  QUPostUpdateWindowController.m
//  Queued
//
//  Created by Pawel Niewiadomski on 14.07.2013.
//  Copyright (c) 2013 Pawel Niewiadomski. All rights reserved.
//

#import <Buffered.h>
#import <BUProfilesMonitor.h>

#import "QUPostUpdateWindowController.h"

@interface QUPostUpdateWindowController ()

@end

@implementation QUPostUpdateWindowController

- (instancetype) initWithBuffered:(Buffered *)buffered andProfilesMonitor:(BUProfilesMonitor *)profilesMonitor {

    self = [super initWithWindowNibName:@"QUPostUpdateWindowController"];
    if (self) {
        _profiles = [NSArrayController new];
        _buffered = buffered;
        _profilesMonitor = profilesMonitor;
    }
    return self;
}

- (void) dealloc {
    [_profilesMonitor removeObserver:self forKeyPath:@"profiles"];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    [self.window setAnimationBehavior:NSWindowAnimationBehaviorDocumentWindow];
    [_profiles setContent:_profilesMonitor.profiles];
    [_profilesMonitor addObserver:self forKeyPath:@"profiles" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([@"profiles" isEqualToString:keyPath]) {
        @synchronized(self) {
            NSArray * profiles = [change objectForKey:NSKeyValueChangeNewKey];
            
            [self.profiles setContent:profiles];
        }
    }
}

- (IBAction)cancel:(id)sender {
    [self.window close];
}

- (IBAction)send:(id)sender {
}

#pragma mark -
#pragma mark NSCollectionView

#pragma mark -
@end
