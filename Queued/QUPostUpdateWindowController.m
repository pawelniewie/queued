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
@property (assign) BOOL textInAutocomplete;
@property (assign) BOOL textInCommandHandling;
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

- (void)showWindow:(id)sender {
    [self.window center];
    [super showWindow:sender];
    [self.window setLevel:NSFloatingWindowLevel];
    self.text.string = @"";
}

- (void)showWindow:(id)sender withUrl: (NSString*) url {
    [self showWindow:sender];
    self.text.string = url;
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

- (void)windowWillClose:(NSNotification *)notification {
    [[QUAppDelegate instance] activatePreviousApplication];
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
- (void)textDidChange:(NSNotification *)notification {
    if(notification.object == self.text)
    {
        if (!self.textInAutocomplete && !self.textInCommandHandling) {
            NSUInteger insertionPoint = [self.text selectedRange].location;
            __block NSString *string = [self.text string];
            
            [string enumerateSubstringsInRange:NSMakeRange(0, string.length) options:NSStringEnumerationByWords|NSStringEnumerationSubstringNotRequired usingBlock:^(NSString *word, NSRange wordRange, NSRange enclosingRange, BOOL *stop) {
                if (NSLocationInRange(insertionPoint, wordRange) || insertionPoint == wordRange.location + wordRange.length) {
                    if (wordRange.location > 0 && [string characterAtIndex:wordRange.location - 1] == '@'
                        && (wordRange.location < 2 || [string characterAtIndex:wordRange.location - 2] != '@')) {
                        self.textInAutocomplete = YES;
                        @try {
                            [self.text complete:self];
                        } @finally {
                            self.textInAutocomplete = NO;
                        }
                        *stop = YES;
                    }
                }
            }];
        }
    }
}

- (NSArray *)textView:(NSTextView *)textView completions:(NSArray *)words forPartialWordRange:(NSRange)charRange indexOfSelectedItem:(NSInteger *)index {
    if (textView == self.text && charRange.location > 0 && [textView.string characterAtIndex:charRange.location - 1] == '@') {
        NSString *string = [textView.string substringWithRange:NSMakeRange(charRange.location, charRange.length)];
        if (string != nil && string.length >= 2) {
            NSManagedObjectContext *context = [[QUAppDelegate instance] managedObjectContext];
            NSFetchRequest *request = [NSFetchRequest new];
            request.entity = [NSEntityDescription entityForName:@"UserSuggestion" inManagedObjectContext:context];
            request.predicate = [NSPredicate predicateWithFormat:@"username BEGINSWITH[cd] %@", string];
            request.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey: @"username" ascending:YES]];
            
            NSError *error;
            NSArray *fetchedNames = [context executeFetchRequest:request error:&error];
            
            if (error == nil) {
                return [fetchedNames valueForKey:@"username"];
            }
        }
    }
    return words;
}

- (BOOL)textView:(NSTextView *)aTextView doCommandBySelector:(SEL)aSelector {
    self.textInCommandHandling = YES;
    @try {
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
    @finally {
        self.textInCommandHandling = NO;
    }
}
#pragma mark -
@end
