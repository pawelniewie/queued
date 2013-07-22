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
#import "QUAppDelegate.h"

@interface QUPostUpdateWindowController ()

@end

@implementation QUPostUpdateWindowController

- (instancetype) initWithBuffered:(Buffered *)buffered andProfilesMonitor:(BUProfilesMonitor *)profilesMonitor {

    self = [super initWithWindowNibName:@"QUPostUpdateWindowController"];
    if (self) {
        self.profiles = [NSArrayController new];
        _buffered = buffered;
        _profilesMonitor = profilesMonitor;
    }
    return self;
}

- (void) dealloc {
    [_profilesMonitor removeObserver:self forKeyPath:@"profiles"];
    [self.profilesCollectionView removeObserver:self forKeyPath:@"selectionIndexes"];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    [self.window setAnimationBehavior:NSWindowAnimationBehaviorDocumentWindow];
    [self.profiles setContent:_profilesMonitor.profiles];
    [_profilesMonitor addObserver:self forKeyPath:@"profiles" options:NSKeyValueObservingOptionNew context:nil];
    [self.profilesCollectionView addObserver:self forKeyPath:@"selectionIndexes" options:NSKeyValueObservingOptionNew context:nil];
    [self.sendingProgressIndicator setHidden:YES];
}

- (void) windowDidBecomeKey:(NSNotification *)notification {
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
    [self.window makeFirstResponder:self.text];
}

- (void) windowWillClose:(NSNotification *)notification {
    [NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([@"profiles" isEqualToString:keyPath]) {
        @synchronized(self) {
            NSArray * profiles = change[NSKeyValueChangeNewKey];
            
            [self.profiles setContent:profiles];
        }
    } else if ([@"selectionIndexes" isEqualToString:keyPath] && object == self.profilesCollectionView) {
        __block BOOL twitterSelected = NO;
        [[[self.profiles arrangedObjects] objectsAtIndexes:self.profilesCollectionView.selectionIndexes] enumerateObjectsUsingBlock:^(BUProfile* profile, NSUInteger idx, BOOL *stop) {
            if ([profile isTwitter]) {
                twitterSelected = YES;
                *stop = YES;
            }
        }];
        self.twitterSelected = twitterSelected;
    }
}

- (IBAction)cancel:(id)sender {
    [self.window close];
}

- (IBAction)send:(id)sender {
    [self.sendButton setEnabled:NO];
    [self.cancelButton setEnabled:NO];
    [self.sendingProgressIndicator setHidden:NO];
    [self.sendingProgressIndicator startAnimation:self];
    NSArray *profiles = [self.profiles.arrangedObjects objectsAtIndexes: [self.profilesCollectionView selectionIndexes]];
    
    [_buffered createUpdate:[BUNewUpdate updateWithText:self.text.string andProfiles:profiles] withCompletionHandler:^(NSError *error) {
        [self.sendButton setEnabled:YES];
        [self.cancelButton setEnabled:YES];
        [self.sendingProgressIndicator setHidden:YES];
        [self.sendingProgressIndicator stopAnimation:self];
        if (error == nil) {
            self.text.string = @"";
            [self.profilesCollectionView setSelectionIndexes:[NSIndexSet indexSet]];
            [self.window close];
            [[QUAppDelegate instance] reloadPendingUpdates:self];
        }
    }];
}

#pragma mark -
#pragma mark NSTextView Delegate
- (BOOL)textView:(NSTextView *)aTextView doCommandBySelector:(SEL)aSelector {
    if (aTextView == self.text) {
        if (aSelector == @selector(insertTab:)) {
            [[aTextView window] selectNextKeyView:self];
            return YES;
        }
        if (aSelector == @selector(insertBacktab:)) {
            [[aTextView window] selectPreviousKeyView:self];
            return YES;
        }
    }
    return NO;
}
#pragma mark -
@end
